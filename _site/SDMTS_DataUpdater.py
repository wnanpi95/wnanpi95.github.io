import os
import gtfs_realtime_pb2
import urllib
import pandas as pd
import datetime

bbox = 0.001
context_data_path = "./SDMTS_context_data/"
web_page_resource_path = "./d3js-test/"
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
        trip_idTOshape_id[trip_id] = shape_id.rstrip('\n')

shapes = pd.read_csv(context_data_path+"shapes_unique.txt")
dynamic_table = pd.read_csv(web_page_resource_path+"stop_edge_table.txt")
##################################################################################################

# Feed Manager
##################################################################################################
class GTFS_feed_manager:

    def __init__(self):
        self.active_trips = dict()

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
        shape_id = str(trip_idTOshape_id[trip_id])
        shape_set = shapes.loc[shapes['shape_id'] == shape_id]
        return shape_set

    def get_candidate_shapes(self, info,  shape_set):

        candidate_indices = []
        latitude  = info[2]
        longitude = info[3]
        for index, shape in shape_set.iterrows():
            latSep = abs(shape.shape_pt_lat - latitude)
            lonSep = abs(shape.shape_pt_lon - longitude)

            if latSep < bbox:
                if lonSep < bbox:
                    candidate_indices.append(index)
        candidate_shape_set = shape_set.loc[shape_set.index.isin(candidate_indices)]
        return candidate_shape_set

    def get_shape_pt(self, info, candidate_shape_set):
        shape_index = -1
        sepMin = 9999.9

        latitude = info[2]
        longitude = info[3]

        for index, shape in candidate_shape_set.iterrows():
            latSep = abs(shape.shape_pt_lat - latitude)
            lonSep = abs(shape.shape_pt_lon - longitude)

            sep = latSep*latSep + lonSep*lonSep

            if sep < sepMin:
                sepMin = sep
                shape_index = index

            if shape_index != -1:
                shape_pt = candidate_shape_set.loc[candidate_shape_set.index == shape_index]
                return shape_pt
            else:
                return pd.DataFrame()

    def record_swap(self, record_new, record_old):

        distance_traveled = record_new[2].iloc[0]['shape_dist_traveled']\
                          - record_old[2].iloc[0]['shape_dist_traveled']
        time_duration = record_new[1] - record_old[1]

        timestamp = record_new[1]

        shape_id = record_old[2].iloc[0]['shape_id']
        vel_avg = distance_traveled / time_duration
        hour = datetime.datetime.fromtimestamp(timestamp).strftime('%H')
        day = datetime.datetime.fromtimestamp(timestamp).weekday()
        print hour
        print day

    def update(self):

        # dump inactive trips if they don't show up on feed for 5 checks
        for trip_id, trackee in self.active_trips.iteritems():
            trackee[0] = trackee[0] - 1
            if trackee[0] <= 0:
                del self.active_trips[trip_id]

        feed = self.get_feed()
        info_block = self.get_info_block(feed)

        # for info in block testing
        info = info_block[0]
        timestamp = info[0]
        shape_set = self.get_shape_subset(info[1])
        candidate_shape_set = self.get_candidate_shapes(info, shape_set)
        shape_pt = self.get_shape_pt(info, candidate_shape_set)

        if shape_pt.empty:
            print "yew"
            #continue
        else:
            record_new = (5, timestamp, shape_pt)

        if info[1] in self.active_trips:
            record_old = self.active_trips[info[1]]
            #if record_new[1] != record_old[1]:
            self.record_swap(record_new, record_old)
            self.active_trips[info[1]] = record_new
        else:
            self.active_trips[info[1]] = record_new

        if info[1] in self.active_trips:
            record_old = self.active_trips[info[1]]
            self.record_swap(record_new, record_old)
            self.active_trips[info[1]] = record_new
##################################################################################################

feed_manager = GTFS_feed_manager()
feed_manager.update()





