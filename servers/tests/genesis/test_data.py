from describe import expect, Stub
from unittest import TestCase

from genesis.data import Account, InvocationMessage


class DescribeAccount(TestCase):
    def test_it_should_hash_passwords(self):
        account = Account.create('jeff', 'password')
        # sha512
        hashed = 'b109f3bbbc244eb82441917ed06d618b9008dd09b3befd1b5e07394c706a8bb980b1d7785e5976ec049b46df5f1326af5a2ea6d103fd07c95385ffab0cacbc86'
        expect(account) == Account('jeff', hashed)

    def test_it_can_be_in_dictionary(self):
        container = {
            Account('user1', 'pwd1'): 1,
        }
        expect(container[Account('user1', 'pwd1')]) == 1

class DescribeInvocationMessage(TestCase):
    def test_it_should_generate_new_ids(self):
        msg1 = InvocationMessage()
        msg2 = InvocationMessage()
        expect(msg1.id) != msg2

class DescribeInvocationMessageSubclass(TestCase):
    class MyMessage(InvocationMessage):
        name = 'my_message'
        MAPPING = ('health', 'has_cookie', 'near_cookie_monster')

    def test_it_has_subclass_features_for_specific_messages(self):
        m = self.MyMessage(100, near_cookie_monster=True, has_cookie=False)
        expect(m[0]) == 100
        expect(m['health']) == 100
        expect(m[1]) == m['has_cookie'] == False
        expect(m[2]) == m['near_cookie_monster'] == True
        expect('health' in m).to.be_truthy()

    def test_it_can_create_message_from_json_rpc(self):
        m = self.MyMessage.create({
            'method': 'my_message',
            'params': [100, True, False, 0],
            'id': 1337,
        })
        expect(m) == self.MyMessage(100, True, False, id=1337)

    def test_it_can_generate_json_rpc(self):
        m = self.MyMessage(100, True, False, id=1337)
        expect(m.to_network()) == {
            "method": 'my_message',
            "params": [100, True, False, 0],
            "id": '1337',
        }


