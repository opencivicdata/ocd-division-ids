import ocdid
import unittest

test_ocdids = [
    ('ocd-division/country:us/court_of_appeals:10/district_court:colorado',True),
    ('ocd-division/country:us',True),
    ('ocd-division/country:us/state:ny/county:montgomery/place:some_town',False),
    ('invalid_ocdid',False)
    ]

test_match_name = [
    ('ocd-division/country:us/state:sd/county:beadle','place','belle_prairie',('ocd-division/country:us/state:sd/county:beadle/place:belle_prairie', 100)),
    ('ocd-division/country:us/state:al','county','marion',('ocd-division/country:us/state:al/county:marion', 100)),
    ('ocd-division/country:us/state:al','county','3',(None, -1))
    ]

test_match_type = [
    ('ocd-division/country:us/state:sd/place:sioux_falls','council',5,'council_district'),
    ('ocd-division/country:us/state:al','county',67,'county'),
    ('ocd-division/country:us/state:al','district',66,'county'),
    ('ocd-division/country:us/state:al','county',6,'No match')
    ]

test_name_search = [
    ('marion',10),
    ('1',10),
    ('blah',0),
    ('#$%',0),
    ('dahlgren',4)
    ]

test_type_name_search = [
    ('county','marion',10),
    ('county','custer',6),
    ('sldl','1',10),
    ('county','a_lot_of_gibberish',0),
    ('cd','#$%',0)
    ]

class TestOcdid(unittest.TestCase):

    def testIsOcdid(self):
        for test_id,is_valid in test_ocdids:
            self.assertEqual(is_valid, ocdid.is_ocdid(test_id))

    def testMatchName(self):
        for prefix,dist_type,dist_name,result in test_match_name:
            self.assertEqual(result, ocdid.match_name(prefix,dist_type,dist_name))

    def testMatchType(self):
        for prefix,dist_type,dist_len,result in test_match_type:
            self.assertEqual(result, ocdid.match_type(prefix,dist_type,dist_len))
        
    def testSearchName(self):
        # order may not be static, testing against a match_count
        for name,match_count in test_name_search:
            self.assertEqual(match_count, len(ocdid.name_search(name)))

    def testTypeNameSearch(self):
        # order may not be static, testing against a match_count
        for dist_type,dist_name,match_count in test_type_name_search:
            self.assertEqual(match_count, len(ocdid.type_name_search(dist_type,dist_name)))

if __name__ == '__main__':
    unittest.main()
