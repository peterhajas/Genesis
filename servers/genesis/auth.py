from genesis.data import Account, ErrorCodes

class MemoryAuth(object):
    def __init__(self):
        self.accounts = {}  # user -> account

    def create(self, username, password):
        if username in self.accounts:
            # error
            return {
                'reason': 'Account already exists',
                'code': ErrorCodes.USERNAME_TAKEN,
            }
        self.accounts[username] = Account.create(username, password)
        return {}  # success

    def verify(self, account):
        if account.username in self.accounts:
            return self.accounts[account.username] == account
        return False

