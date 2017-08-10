import os
import gtfs_realtime_pb2
import urllib
import pandas as pd

bbox = 0.001
context_data_path = "./SDMTS_context_data/"
url = "https://realtime.sdmts.com/api/api/gtfs_realtime/vehicle-positions-for-agency/MTS.pb?key="
key = "65855fcd-32a6-4ddc-8b70-ab58f6806e21"
path = "./"

data_dest = path+"data.pb"

#Data Tables (Contextual and dynamically updated)
##################################################################################################
trip_idTOshape_id = dict()
with open(context_data_path+"trip_idTOshape_id.txt", 'r') as f:
    for line in f:
        (trip_id, shape_id) = line.split(",")
        trip_idTOshape_id[trip_id] = shape_id

shapes = pd.read_csv(context_data_path+"shapes_unique.txt")
dynamic_table = pd.read_csv(context_data_path+"stop_edge_table.txt")
##################################################################################################

# Feed Manager
##################################################################################################
class GTFS_feed_manager:

    def __init__(self):
        self.active_trips = []

    def get_feed(self):
        urllib.urlretrieve(url+key, filename=data_dest)
        d = open(data_dest, 'rb')
        raw_data = gtfs_realtime_pb2.FeedMessage()
        raw_data.ParseFromString(d.read())
        d.close()
        os.system("rm "+data_dest)
        return raw_data

    def get_info(self, entity):
        timestamp = entity.vehicle.timestamp
        trip_id = entity.vehicle.trip.trip_id
        latitude = entity.vehicle.position.latitude
        longitude = entity.vehicle.position.longitude
        return (timestamp, trip_id, latitude, longitude)

    def get_info_block(self, raw_data):
        info_block = []
        for entity in raw_data.entity:
            info = self.get_info(entity)
            info_block.append(info)
        return info_block

    ## NEEDS TO BE FIXED
    def get_shape_subset(self, trip_id):
        shape_id = trip_idTOshape_id[trip_id]
        return shapes[shapes['shape_id'] == shape_id]



    def update(self):
        feed = self.get_feed()
        info_block = self.get_info_block(feed)
        shape = self.get_shape_subset(info_block[0][1])
##################################################################################################

feed_manager = GTFS_feed_manager()
feed_manager.update()





