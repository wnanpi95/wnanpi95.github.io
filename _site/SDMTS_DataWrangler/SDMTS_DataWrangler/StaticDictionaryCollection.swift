//
//  StaticDictionaryCollection.swift
//  SDMTS_DataWrangler
//
//  Created by Will An on 8/9/17.
//  Copyright © 2017 Will An. All rights reserved.
//

import Foundation

struct ShapeIndex {
    let shape_id: String
    let start_idx: Int
    let stop_idx: Int
}

class StaticDictionaryCollection {
    
    let resourcePath: String
    
    // trips.txt
    var trip_idTOshape_id: [String: String]?
    var shape_idTOroute_direction: [String: RouteDirection]?
    
    // shapes.txt
    var shape_idTOshapes_array: [String: [Shape]]?
    
    // places.txt
    var place_idTOposition: [String: Position]?
    
    // place_patterns.txt
    var route_directionTOplace_id_array: [RouteDirection: [String]]?
    
    // stops.txt
    var stop_idTOstop_position: [String: Position]?
    
    // stop_times.txt
    var trip_idTOstop_id_array: [String: [String]]?
    
    init(resourcePath: String) {
        self.resourcePath = resourcePath
    }
    
    // shape_stopEdge.txt
    var stop_edge_idTOshape_indices: [String: [ShapeIndex]]?
    
    // shapes_unique.txt
    var shape_idTOshapeSeq_array: [String: [ShapeSeq]]?
    
    //stop_edges.txt
    var stop_edge_id_array: [String]?
    
    func shape_stopEdge() {
        // MARK: iterating through shape_stopEdge.txt
        let shapesPath = resourcePath+"shape_stopEdge.txt"
        let shapesStringLines =
            readFile(path: shapesPath)?.components(separatedBy: "\n")
        let shapesCount = (shapesStringLines?.count)! - 1
        
        // * stop_edge_id -> shape_indices
        stop_edge_idTOshape_indices = [:]
        for i in 1..<shapesCount {
            guard let shapesRow =
                shapesStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let shape_id      = shapesRow[0]
            let startIdx      = Int(shapesRow[1])
            let stopIdx       = Int(shapesRow[2])
            let stop_edge_id  = shapesRow[3]
            let shapeIndex    = ShapeIndex(shape_id: shape_id,
                                             start_idx: startIdx!,
                                             stop_idx: stopIdx!)
            
            if stop_edge_idTOshape_indices?[stop_edge_id] == nil {
                stop_edge_idTOshape_indices?[stop_edge_id] = [shapeIndex]
            }
        }
        // ******************************************************************//
    }
    
    func trips() {
        // MARK: iterating through trips.txt
        let tripsPath = resourcePath+"trips.txt"
        let tripsStringLines =
            readFile(path: tripsPath)?.components(separatedBy: "\r\n")
        let tripsCount = (tripsStringLines?.count)!
        
        // * trip_id -> shape_id
        trip_idTOshape_id = [:]
        shape_idTOroute_direction = [:]
        for i in 1..<tripsCount {
            guard let tripsRow =
                tripsStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            let route = tripsRow[0]
            let trip_id = tripsRow[2]
            let direction = tripsRow[5]
            let shape_id = tripsRow[7]
            
            trip_idTOshape_id?[trip_id] = shape_id
            
            let routeDirection = RouteDirection(route: route,
                                                direction: direction)
            shape_idTOroute_direction?[shape_id] = routeDirection
        }
        // ******************************************************************//
    }
    
    func stop_edge() {
        // MARK: iterating through stop_edge.txt
        let stop_edgePath = resourcePath+"stop_edges.txt"
        let stop_edgeStringLines =
            readFile(path: stop_edgePath)?.components(separatedBy: "\n")
        let stop_edgeCount = (stop_edgeStringLines?.count)!
        
        // * [stop_edge]
        
        stop_edge_id_array = []
        for i in 1..<stop_edgeCount {
            guard let stop_edgeRow =
                stop_edgeStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let stop_edge_id = stop_edgeRow[0]
            
            stop_edge_id_array?.append(stop_edge_id)
            
        }
        // ******************************************************************//
    }
    
    func shapes() {
        // MARK: iterating through shapes.txt
        let shapesPath = resourcePath+"shapes.txt"
        let shapesStringLines =
            readFile(path: shapesPath)?.components(separatedBy: "\r\n")
        let shapesCount = (shapesStringLines?.count)! - 1
        
        // * shape_id -> shapes_array
        shape_idTOshapes_array = [:]
        for i in 1..<shapesCount {
            guard let shapesRow =
                shapesStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let shape_id      = shapesRow[0]
            let latitude      = Float(shapesRow[1])
            let longitude     = Float(shapesRow[2])
            let dist_traveled = Float(shapesRow[4])
            let shape = Shape(latitude: latitude!,
                              longitude: longitude!,
                              dist_traveled: dist_traveled!)
            
            if shape_idTOshapes_array?[shape_id] == nil {
                shape_idTOshapes_array?[shape_id] = [shape]
            } else if shape_idTOshapes_array?[shape_id]?.last?.dist_traveled
                != shape.dist_traveled {
                shape_idTOshapes_array?[shape_id]?.append(shape)
            }
        }
        // ******************************************************************//
    }
    
    func shapes_unique() {
        // MARK: iterating through shapes_unique.txt
        let shapesPath = resourcePath+"shapes_unique.txt"
        let shapesStringLines =
            readFile(path: shapesPath)?.components(separatedBy: "\n")
        let shapesCount = (shapesStringLines?.count)! - 1
        
        // * shape_id -> shapesSeq_array
        shape_idTOshapeSeq_array = [:]
        for i in 1..<shapesCount {
            guard let shapesRow =
                shapesStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let shape_id      = shapesRow[0]
            let latitude      = Float(shapesRow[1])
            let longitude     = Float(shapesRow[2])
            let sequence      = Int(shapesRow[3])
            let dist_traveled = Float(shapesRow[4])
            let shapeSeq = ShapeSeq(latitude: latitude!,
                              longitude: longitude!,
                              dist_traveled: dist_traveled!,
                              sequence: sequence!)
            
            if shape_idTOshapeSeq_array?[shape_id] == nil {
                shape_idTOshapeSeq_array?[shape_id] = [shapeSeq]
            } else {
                shape_idTOshapeSeq_array?[shape_id]?.append(shapeSeq)
            }
        }
        // ******************************************************************//
    }
    
    func places() {
        //MARK: iterating through places.txt
        let placesPath = resourcePath+"places.txt"
        let placesStringLines =
            readFile(path: placesPath)?.components(separatedBy: "\r\n")
        let placesCount = (placesStringLines?.count)! - 1
        
        place_idTOposition = [:]
        for i in 1..<placesCount {
            guard let placesRow =
                placesStringLines?[i].components(separatedBy: ",") else { continue }
            
            let place_id = placesRow[0]
            guard let place_lat = Float(placesRow[3]) else { continue }
            guard let place_long = Float(placesRow[4]) else { continue }
            let placePosition = Position(latitude: place_lat,
                                         longitude: place_long)
            
            place_idTOposition?[place_id] = placePosition
        }
        
    }
    
    func place_patterns() {
        //MARK: iterating through place_patterns.txt
        let place_patternsPath = resourcePath+"place_patterns.txt"
        let place_patternsStringLines =
            readFile(path: place_patternsPath)?.components(separatedBy: "\r\n")
        let place_patternsCount = (place_patternsStringLines?.count)! - 1
        
        route_directionTOplace_id_array = [:]
        for i in 1..<place_patternsCount {
            guard let place_patternsRow =
                place_patternsStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let route = place_patternsRow[0]
            let direction = place_patternsRow[2]
            let place = place_patternsRow[3]
            
            let routeDirection = RouteDirection(route: route, direction: direction)
            
            if route_directionTOplace_id_array?[routeDirection] == nil {
                route_directionTOplace_id_array?[routeDirection] = [place]
            } else {
                route_directionTOplace_id_array?[routeDirection]?.append(place)
            }
        }
    }
    
    func stop_times() {
        //MARK: iterating through stop_times.txt
        let stop_timesPath = resourcePath+"stop_times.txt"
        let stop_timesStringLines =
            readFile(path:stop_timesPath)?.components(separatedBy: "\r\n")
        let stop_timesCount = (stop_timesStringLines?.count)! - 1
        
        trip_idTOstop_id_array = [:]
        for i in 1..<stop_timesCount {
            guard let stop_timesRow =
                stop_timesStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let trip_id = stop_timesRow[0]
            let stop_id = stop_timesRow[3]
            
            if trip_idTOstop_id_array?[trip_id] == nil {
                trip_idTOstop_id_array?[trip_id] = [stop_id]
            } else {
                trip_idTOstop_id_array?[trip_id]?.append(stop_id)
            }
        }
    }
    
    
    func stops() {
        //MARK: iterating through stops.txt
        let stopsPath = resourcePath+"stops.txt"
        let stopsStringLines =
            readFile(path:stopsPath)?.components(separatedBy: "\r\n")
        let stopsCount = (stopsStringLines?.count)! - 1
        
        stop_idTOstop_position = [:]
        for i in 1..<stopsCount {
            guard let stopsRow =
                stopsStringLines?[i].components(separatedBy: ",") else {
                    continue
            }
            
            let stop_id = stopsRow[0]
            let latitude = Float(stopsRow[2])
            let longitude = Float(stopsRow[3])
            let position = Position(latitude: latitude!, longitude: longitude!)
            
            stop_idTOstop_position?[stop_id] = position
        }
    }
}

func writeDuplicateFreeShapes(resource: StaticDictionaryCollection, output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        let header = ("shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence,shape_dist_traveled\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        file?.write(header!)
        
        for (shape_id, shapes_array) in resource.shape_idTOshapes_array! {
            
            for (index, shape) in shapes_array.enumerated() {
            
            let line = shape_id+","
                + String(shape.latitude)+","
                + String(shape.longitude)+","
                + String(index)+","
                + String(shape.dist_traveled)+"\n"
            
            let newLine = (line as NSString).data(using: String.Encoding.utf8.rawValue)
            
            file?.write(newLine!)
            
            }
        }
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}

func writeStopEdgeTable(resource: StaticDictionaryCollection, output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        let header = ("stop_edge_id,hour,dow,v_avg\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        file?.write(header!)
        
        let dow_array = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        
        for stop_edge_id in resource.stop_edge_id_array! {
            for dow in 0..<7 {
                for hour in 0..<24 {
                    let line = stop_edge_id+","
                        + String(hour)+","
                        + String(dow)+","
                        + "NaN"+"\n"
                    let newLine = (line as NSString).data(using: String.Encoding.utf8.rawValue)
                    
                    file?.write(newLine!)
                }
            }
        }
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}















