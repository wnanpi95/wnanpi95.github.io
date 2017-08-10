import os
import gtfs_realtime_pb2
import urllib
import pandas as pd
import datetime
import numpy as np
from time import sleep

alpha = 0.1
bbox = 0.001
min_distance = 0.005

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
shape_idTOstop_edges = pd.read_csv(context_data_path+"shape_stopEdge.txt")
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
        timestamp = int(entity.vehicle.timestamp)
        trip_id = str(entity.vehicle.trip.trip_id)
        latitude = entity.vehicle.position.latitude
        longitude = entity.vehicle.position.longitude
        return (timestamp, trip_id, latitude, longitude)

    def get_info_block(self, raw_data):
        info_block = []
        for entity in raw_data.entity:
            info = self.get_info(entity)
            if info[1] == "":
                continue
            info_block.append(info)

        return info_block

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

        if not candidate_indices:
            return pd.DataFrame()
        candidate_shape_set = shape_set.loc[shape_set.index.isin(candidate_indices)]
        return candidate_shape_set

    def get_shape_pt(self, info, candidate_shape_set):

        if candidate_shape_set.empty:
            return candidate_shape_set

        shape_index = 0
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
        if distance_traveled < min_distance:
            return
        time_duration = record_new[1] - record_old[1]

        timestamp = record_new[1]

        shape_id = record_old[2].iloc[0]['shape_id']
        start_idx = record_old[2].iloc[0]['shape_pt_sequence']
        stop_idx = record_new[2].iloc[0]['shape_pt_sequence']
        vel_avg = 60 * 60 * distance_traveled / time_duration
        hour = int(datetime.datetime.fromtimestamp(timestamp).strftime('%H'))
        day = int(datetime.datetime.fromtimestamp(timestamp).weekday())

        stop_edges = shape_idTOstop_edges.loc[shape_idTOstop_edges['shape_id'] == shape_id]
        affected_stop_edge_ids = []
        for _, row in stop_edges.iterrows():
            if row.start_idx < stop_idx and row.stop_idx > start_idx:
                affected_stop_edge_ids.append(row.stop_edge_id)

        affected_stop_edge_table = dynamic_table.loc[(dynamic_table['stop_edge_id'].isin(affected_stop_edge_ids))\
                                                 & (dynamic_table['hour'] == hour)\
                                                 & (dynamic_table['dow'] == day)]

        for i, row in affected_stop_edge_table.iterrows():

            if np.isnan(row.v_avg):
                dynamic_table.set_value(i, 'v_avg', vel_avg)
            else:
                dynamic_table.set_value(i, 'v_avg', alpha*vel_avg + (1 - alpha)*vel_avg)

    def update(self):

        # dump inactive trips if they don't show up on feed for 5 checks
        for trip_id, trackee in self.active_trips.items():
            trackee[0] = trackee[0] - 1
            if trackee[0] <= 0:
                del self.active_trips[trip_id]

        feed = self.get_feed()
        info_block = self.get_info_block(feed)
        for info in info_block:
            timestamp = info[0]
            shape_set = self.get_shape_subset(info[1])
            if shape_set.empty:
                continue
            candidate_shape_set = self.get_candidate_shapes(info, shape_set)
            shape_pt = self.get_shape_pt(info, candidate_shape_set)

            if shape_pt.empty:
                continue
            else:
                record_new = [5, timestamp, shape_pt]
            if info[1] in self.active_trips:
                record_old = self.active_trips[info[1]]
                if record_new[1] != record_old[1]:
                    self.record_swap(record_new, record_old)
                    self.active_trips[info[1]] = record_new
                    print "swapped"
            else:
                self.active_trips[info[1]] = record_new

##################################################################################################

feed_manager = GTFS_feed_manager()
while 1:
    print "round start"
    feed_manager.update()
    dynamic_table.to_csv(path_or_buf=web_page_resource_path+"stop_edge_table_test.txt", index=False, na_rep='NaN')
    sleep(60)

