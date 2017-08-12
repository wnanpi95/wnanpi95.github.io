//
//  StopEdge.swift
//  SDMTS_DataWrangler
//
//  Created by Will An on 8/9/17.
//  Copyright © 2017 Will An. All rights reserved.
//

import Foundation

struct StopEdge: Hashable {
    
    let stop_edge_id: String
    let stop_0: String                  // Makes data set 3x larger, but allows
    let stop_1: String                  // for faster and easier parsing downstream
    
    init(stop_a: String, stop_b: String) {
       
        self.stop_0 = min(stop_a, stop_b)
        self.stop_1 = max(stop_a, stop_b)
        self.stop_edge_id = stop_0+"_"+stop_1
    }
    
    var hashValue: Int {
        return stop_edge_id.hashValue
    }
    
    static func == (lhs: StopEdge, rhs: StopEdge) -> Bool {
        return lhs.stop_edge_id == rhs.stop_edge_id
    }

}

func stopEdgeSet(resource: StaticDictionaryCollection) -> Set<StopEdge> {
    
    var returnSet = Set<StopEdge>()
    
    guard resource.trip_idTOstop_id_array != nil else {
        print("stop_times.txt NOT read")
        return returnSet
    }
    
    for (_, stop_id_array) in resource.trip_idTOstop_id_array! {
        
        let count = stop_id_array.count - 1
        
        for i in 0..<count {
            let stop_a = stop_id_array[i]
            let stop_b = stop_id_array[i+1]
            let newStopEdge = StopEdge(stop_a: stop_a, stop_b: stop_b)
            returnSet.insert(newStopEdge)
        }
        
    }
    
    return returnSet
}

func writeStopEdges(stopEdgeSet: Set<StopEdge>, output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        let header = ("stop_edge_id,stop_0,stop_1\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        file?.write(header!)
        
        for stopEdge in stopEdgeSet {
            
            let line = stopEdge.stop_edge_id+","
                       + stopEdge.stop_0+","
                       + stopEdge.stop_1+"\n"
            
            let newLine = (line as NSString).data(using: String.Encoding.utf8.rawValue)
            
            file?.write(newLine!)
        }
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}

struct ShapeStopEdge {
    let start_idx: Int
    let stop_idx: Int
    let stop_edge_id: String
}

struct ShapeStop {
    let idx: Int
    let stop_id: String
}

func findCandidates(position: Position, shapeSet: [ShapeSeq]) -> [Int] {
    let bbox: Float = 0.01
    var candidateIndices: [Int] = []
    let upperLat = position.latitude + bbox
    let lowerLat = position.latitude - bbox
    
    let upperLon = position.longitude + bbox
    let lowerLon = position.longitude - bbox
    
    for (index, shape) in shapeSet.enumerated() {
        
        let lat = shape.latitude
        let lon = shape.longitude
        
        if lat >= lowerLat && lat <= upperLat {
            if lon >= lowerLon && lon <= upperLon {
                candidateIndices.append(index)
            }
        }
    }
    return candidateIndices
    
}
func findIndex(position: Position, candidates: [Int], shapeSet: [ShapeSeq]) -> Int {
    
    var sepMin: Float = 9999.9
    var nearestIndex: Int? = nil
    
    
    for index in candidates {
        let shape = shapeSet[index]
        let sepLat = (position.latitude-(shape.latitude))*(position.latitude-(shape.latitude))
        let sepLon = (position.longitude-(shape.longitude))*(position.longitude-(shape.longitude))
        if sepLat+sepLon < sepMin {
            sepMin = sepLat+sepLon
            nearestIndex = index
        }
    }
    
    return nearestIndex!
}

func shape_idTOshapeStopEdges(resource: StaticDictionaryCollection) -> [String: [ShapeStopEdge]] {
    var returnDict: [String: [ShapeStopEdge]] = [:]
    
    // Refactor these if you find time (automate print statements)
    
    guard resource.shape_idTOshapeSeq_array != nil else {
        print("shapes_unique.txt NOT read")
        return returnDict
    }
    
    guard resource.stop_idTOstop_position != nil else {
        print("stops.txt NOT read")
        return returnDict
    }
    
    guard resource.trip_idTOstop_id_array != nil else {
        print("stop_times.txt NOT read")
        return returnDict
    }
    
    guard resource.trip_idTOshape_id != nil else {
        print("trips.txt NOT read")
        return returnDict
    }
    
    var shape_idTOshapeStop: [String: [ShapeStop]] = [:]
    for (trip_id, stop_id_array) in resource.trip_idTOstop_id_array! {
        
        guard trip_id != "124" else { continue } // skip "air" trip
        
        let shape_id = resource.trip_idTOshape_id?[trip_id]
        guard shape_id != "" else { continue }   // skip "COR" trip
        
        let shape_array = resource.shape_idTOshapeSeq_array?[shape_id!]
        shape_idTOshapeStop[shape_id!] = []
        returnDict[shape_id!] = []
        
        
        for stop_id in stop_id_array {
            
            let position = resource.stop_idTOstop_position?[stop_id]
            
            let candidateIndices = findCandidates(position: position!,
                                                  shapeSet: shape_array!)
            
            let index = findIndex(position: position!,
                                  candidates: candidateIndices,
                                  shapeSet: shape_array!)
            
            let newShapeStop = ShapeStop(idx: index, stop_id: stop_id)
            
            shape_idTOshapeStop[shape_id!]?.append(newShapeStop)
        }
    }
    
    for (shape_id, shapeStop) in shape_idTOshapeStop {
        let count = shapeStop.count - 1
        
        for i in 0..<count {
            let startIdx = shapeStop[i].idx
            let stopIdx = shapeStop[i+1].idx
            
            let stop_a = shapeStop[i].stop_id
            let stop_b = shapeStop[i+1].stop_id
            let newStopEdge = StopEdge(stop_a: stop_a, stop_b: stop_b)
            
            let newShapeStopEdge = ShapeStopEdge(start_idx: startIdx,
                                                 stop_idx: stopIdx,
                                                 stop_edge_id: newStopEdge.stop_edge_id)
            
            returnDict[shape_id]?.append(newShapeStopEdge)
        }
    }
    
    return returnDict
}

func writeShape_StopEdge(shape_idTOShapeStopEdges: [String: [ShapeStopEdge]],
                         output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        let header = ("shape_id,start_idx,stop_idx,stop_edge_id\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        file?.write(header!)
        
        for (shape_id, shapeStopEdges) in shape_idTOShapeStopEdges {
            
            for shapeStopEdge in shapeStopEdges {
                
                let line = shape_id+","
                    + String(shapeStopEdge.start_idx)+","
                    + String(shapeStopEdge.stop_idx)+","
                    + shapeStopEdge.stop_edge_id+"\n"
                
                let newLine = (line as NSString).data(using: String.Encoding.utf8.rawValue)
                
                file?.write(newLine!)
            }

        }
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}

func stop_edge_idTOshape_pts(resource: StaticDictionaryCollection) -> [String: [Position]] {
    
    var returnDict: [String: [Position]] = [:]
    
    for (stop_edge_id, shapeIndices) in resource.stop_edge_idTOshape_indices! {
        returnDict[stop_edge_id] = []
        
        let shape_array = resource.shape_idTOshapes_array?[shapeIndices[0].shape_id]
        
        for shapeIndex in shapeIndices {
            let startIdx = shapeIndex.start_idx
            var stopIdx = shapeIndex.stop_idx
            
            
            // Hacky fix, consider reevaluating
            if stopIdx < startIdx {
                let increment = (shapeIndices.count - 1) / (shapeIndices.count - 1 - startIdx)
                stopIdx = startIdx + increment
            }
            
            for i in startIdx...stopIdx {
                let latitude = shape_array?[i].latitude
                let longitude = shape_array?[i].longitude
                let position = Position(latitude: latitude!,
                                       longitude: longitude!)
                
                if i >= startIdx + 2 {
                    let last = (returnDict[stop_edge_id]?.count)! - 1
                    
                    var dropped = false
                    
                    if abs(latitude! - (returnDict[stop_edge_id]?[last].latitude)!) > 0.001 {
                        if abs(latitude! - (returnDict[stop_edge_id]?[last-1].latitude)!) > 0.001 {
                            returnDict[stop_edge_id]?.removeLast()
                            dropped = true
                        }
                    }
                    
                    if !dropped {
                        if abs(longitude! - (returnDict[stop_edge_id]?[last].longitude)!) > 0.001{
                            if abs(longitude! - (returnDict[stop_edge_id]?[last-1].longitude)!) > 0.001{
                                returnDict[stop_edge_id]?.removeLast()
                            }
                        }
                    }
                    
                }
                
                returnDict[stop_edge_id]?.append(position)
            }
        }
    }
    
    return returnDict
}

let entryStartFirst = "\n\t\t{\n"
let entryStart = ",\n\t\t{\n"
let entryEnd = "\t\t}"

func writeStopEdge_shapePtsJSON(stop_edge_idTOshape_pts: [String: [Position]],
                            output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        
        file?.write(("{\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        
        for (stop_edge_id, shape_pt_array) in stop_edge_idTOshape_pts {
            
            file?.write(("\t\""+stop_edge_id+"\": [" as NSString).data(using: String.Encoding.utf8.rawValue)!)
            
            var first = true
            
            for shape_pt in shape_pt_array {
                
                if first {
                    first = false
                    file?.write((entryStartFirst as NSString).data(using: String.Encoding.utf8.rawValue)!)
                } else {
                    file?.write((entryStart as NSString).data(using: String.Encoding.utf8.rawValue)!)
                }
                
                let entry = "\t\t\t\"shape_pt_lat\": "+String(shape_pt.latitude)
                        + ",\n\t\t\t\"shape_pt_lon\": "+String(shape_pt.longitude)+"\n"
                
                
                
                file?.write((entry as NSString).data(using: String.Encoding.utf8.rawValue)!)
                
                
                file?.write((entryEnd as NSString).data(using: String.Encoding.utf8.rawValue)!)
                
            }
            
            first = true
            file?.write(("\n\t],\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        }
        
        file?.write(("}" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}

func writeStopEdge_shapePts(stop_edge_idTOshape_pts: [String: [Position]],
                         output: String) {
    let file: FileHandle? = FileHandle(forWritingAtPath: output)
    
    if file != nil {
        let header = ("stop_edge_id,shape_pt_lat,shape_pt_lon\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        file?.write(header!)
        
        for (stop_edge_id, shape_pt_array) in stop_edge_idTOshape_pts {
            
            for shape_pt in shape_pt_array {
                
                let line = stop_edge_id+","
                    + String(shape_pt.latitude)+","
                    + String(shape_pt.longitude)+"\n"
                
                let newLine = (line as NSString).data(using: String.Encoding.utf8.rawValue)
                
                file?.write(newLine!)
            }
            
        }
        
        file?.closeFile()
        
    } else {
        print("Ooops! Something went wrong!")
    }
}





















