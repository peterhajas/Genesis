import os

from genesis.shell import ProcessQuery
from git import Repo


def get_scm(project_path):
    """Returns an instance of an SCM manager.

    Returns None if no supported SCM manager exists for the directory.
    """
    if os.path.exists(os.path.join(project_path, '.git')):
        return Git(project_path)
    return None


class SCM(object):
    "The basic interface for supporting another SCM."
    def branches(self):
        "Lists all the branch names that can be checked-out to."
        raise NotImplemented

    def checkout(self, branch_name):
        """Switches to the given branch_name (provided from branches),
        Returns True if checkout was successful, and False otherwise.
        """
        raise NotImplemented

    def current_branch(self):
        raise NotImplemented

    def diff_stats(self):
        raise NotImplemented


def _diff_stats(filediff):
    data = {'additions': 0, 'deletions': 0, 'old': None, 'new': None}
    lines = filediff.split('\n')
    state = 'filename'
    for i, line in enumerate(lines):
        if line.startswith('@@'):
            state = 'diff'
        if state == 'filename':
            if line.startswith('---'):
                data['old'] = line[len('--- a/'):]
            if line.startswith('+++'):
                data['new'] = line[len('+++ b/'):]
                if data['old'] is None:
                    data['old'] = data['new']
        elif state == 'diff':
            if line.startswith('-'):
                data['deletions'] += 1
            elif line.startswith('+'):
                data['additions'] += 1
    if not data['new']:
        data['new'] = data['old']
    return data


def _diff_folder(stats):
    """Converts stats of all files to stats with folders:

        stats = {
            "path/to/file": {
                "type": "file",
                "new_file": "path/to/file",
                "old_file": "path/to/old_file",
                "additions": 10,
                "deletions": 10,
            },
            ...
        }

    to become:

        new_stats = {
            "path": {
                "type": "folder",
                "new_file": "path",
                "old_file": "path",
                "additions": 10,
                "deletions": 10,
            }
            ...
        }
    """
    newstats = {}
    for filepath, fstat in stats.items():
        name = filepath.split(os.sep, 1)[0]
        stat = newstats.setdefault(name, {})
        if name != filepath:
            stat['type'] = 'file'
            stat['new'] = stat['old'] = name
        else:
            stat['type'] = 'folder'
            stat['new'], stat['old'] = fstat['new'], fstat['old']
        stat['additions'] = stat.get('additions', 0) + fstat['additions']
        stat['deletions'] = stat.get('deletions', 0) + fstat['deletions']
    return newstats


class Git(SCM):
    def __init__(self, location='..'):
        self.repo = Repo(location)

    def branches(self):
        return [branch.name for branch in self.repo.heads]

    def checkout(self, name):
        "Returns True if branch was checked out."
        if name != self.current_branch():
            try:
                self.repo.heads[self.branches().index(name)].checkout()
            except ValueError:
                # invalid branch name
                return False
        return True

    def current_branch(self):
        return [h.name for h in self.repo.heads if h == self.repo.head.ref][0]

    def diff_stats(self):
        "Diff the working tree."
        stats = {} # file => stat
        diff_index = self.repo.index.diff(None, create_patch=True)
        # files added
        for diff_add in diff_index.iter_change_type('A'):
            fstat = _diff_stats(diff_add.diff)
            stats[fstat['new']] = fstat
        # files deleted
        for diff_rm in diff_index.iter_change_type('D'):
            fstat = _diff_stats(diff_rm.diff)
            stats[fstat['new']] = fstat
        # files moved / renamed
        for diff_mv in diff_index.iter_change_type('R'):
            fstat = _diff_stats(diff_mv.diff)
            stats[fstat['new']] = fstat
        # files modified
        for diff_mod in diff_index.iter_change_type('M'):
            fstat = _diff_stats(diff_mod.diff)
            stats[fstat['new']] = fstat
        return _diff_folder(stats)

