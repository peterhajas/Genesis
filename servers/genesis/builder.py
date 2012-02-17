import os
import mimetypes
import fnmatch

import yaml

from genesis.shell import ShellProxy, ProcessQuery
from genesis.utils import expand, is_windows


def load_yaml(filename):
    with open(filename, 'r') as handle:
        return yaml.load(handle.read())

def save_yaml(filename, obj):
    with open(filename, 'w+') as handle:
        handle.write(yaml.dump(obj))

class IgnoreList(object):
    def __init__(self, ignored):
        self.ignored = list(map(expand, ignored))

    def __contains__(self, filepath):
        matches = fnmatch.fnmatch if is_windows() else fnmatch.fnmatchcase
        return any(matches(filepath, i) for i in self.ignored)

class BuilderConfig(object):
    def __init__(self, config, filepath=None):
        self.config = config # TODO: verify object format
        self.filepath = self._expand(filepath or '~/.genesis.yml')

    def _expand(self, string):
        return expand(string)

    @property
    def project_names(self):
        return self.config.get('projects', {}).keys()

    def _get_project(self, project):
        return self.config.get('projects', {}).get(project, {})

    def get_ignored(self, project):
        return IgnoreList(self._get_project(project).get('ignore', []))

    def get_files(self, project):
        ignored = self.get_ignored(project)
        location = expand(self.get_location(project))
        all_files = []

        for root, dirs, files in os.walk(location):
            for f in files:
                filepath = os.path.join(root, f)
                if filepath in ignored:
                    continue

                s = os.stat(filepath)
                all_files.append({
                    'name': filepath,
                    'size': s.st_size,
                    'modified_time': s.st_mtime,
                    'kind': '',
                    'mimetype': mimetypes.guess_type(f, strict=False),
                })
        return all_files


    def get_actions(self, project):
        return self._get_project(project).get('actions', {})

    def get_location(self, project):
        return expand(self._get_project(project)['location'])

    def get_shell(self, project):
        return self._get_project(project).get('shell', {})

    def get_sources(self, project):
        return self._get_project(project).get('source', [])

    def to_dict(self):
        return self.config

class Project(object):
    def __init__(self, name, config, shell=None):
        self.name = name
        self.config = config
        self._shell = shell
        self._query = None # last ProcessQuery instance
        self._last_action = None

    @property
    def activity(self):
        if not self._query:
            return None
        if self._query.has_terminated and not self._query.can_read:
            return None
        return self._last_action

    @property
    def is_busy(self):
        return self.activity is not None

    @property
    def shell(self):
        if self._shell is None:
            self._shell = self._create_shell()
        return self._shell

    def _create_shell(self):
        "Creates a ShellProxy from the config."
        return ShellProxy(
            executable=expand(self.config.get_shell(self.name)),
            sources=self.config.get_sources(self.name)
        )

    @property
    def actions(self):
        return self.config.get_actions(self.name).keys()

    def perform_action(self, name):
        """Executes the given action, runs ProcessQuery,
        unless another wrapper object or class is provided.

        """
        assert not self.is_busy, "Cannot perform %r, busy running %r" % (name, self._last_action)
        actions = self.config.get_actions(self.name)
        self._last_action = name
        cwd = self.config.get_location(self.name)
        self._query = ProcessQuery(self.shell.run(actions[name], cwd=cwd))
        return self._query


class Builder(object):
    def __init__(self, config):
        self.config = config
        self.projects = {}
        for name in self.config.project_names:
            self.projects[name] = Project(name, self.config)

    @classmethod
    def from_file(cls, filename):
        return cls(BuilderConfig(load_yaml(expand(filename))))

    @property
    def project_names(self):
        return self.projects.keys()

    @property
    def activity(self):
        activities = {}
        for p in self.projects:
            activities[p.name] = p.activity
        return activities

    def _filepath(self, project, filename):
        location = self.config.get_location(project)
        # TODO: escape parent directory access
        filepath = os.path.join(location, filename)
        assert filepath.startswith(location), "Security error: generated filepath %r, when expected prefix of %r" % (
            location, filepath
        )
        return filepath

    def get_files(self, project):
        return self.config.get_files(project)

    def has_file(self, project, filename):
        ignored = self.config.get_ignored(project)
        filepath = self._filepath(project, filename)
        if filepath in ignored:
            return False
        return os.path.exists(filepath)

    def read_file(self, project, filename):
        ignored = self.config.get_ignored(project)
        filepath = self._filepath(project, filename)
        if filepath in ignored:
            return None
        try:
            with open(self._filepath(project, filename), 'r') as handle:
                return handle.read()
        except:
            return None

    def write_file(self, project, filename, contents):
        with open(self._filepath(project, filename), 'w+') as handle:
            handle.write(contents)

