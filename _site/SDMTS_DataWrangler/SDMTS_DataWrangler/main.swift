//
//  main.swift
//  SDMTS_DataWrangler
//
//  Created by Will An on 8/9/17.
//  Copyright © 2017 Will An. All rights reserved.
//

import Foundation

let myIO = IO(dictionaryPath: CommandLine.arguments[1] as NSString)
let myStaticDict = StaticDictionaryCollection(resourcePath: myIO.dictionaryPath)
myStaticDict.stop_times()
myStaticDict.shapes()
myStaticDict.shapes_unique()
myStaticDict.trips()
myStaticDict.stops()
myStaticDict.shape_stopEdge()
myStaticDict.stop_edge()

/*
let myStopEdgeSet = stopEdgeSet(resource: myStaticDict)
writeStopEdges(stopEdgeSet: myStopEdgeSet, output: myIO.dictionaryPath+"stop_edges.txt")
 */

//writeDuplicateFreeShapes(resource: myStaticDict, output: myIO.dictionaryPath+"shapes_unique.txt")

/*
let shape_idTOShapeStopEdges = shape_idTOshapeStopEdges(resource: myStaticDict)
writeShape_StopEdge(shape_idTOShapeStopEdges: shape_idTOShapeStopEdges,
                    output: myIO.dictionaryPath+"shape_stopEdge.txt")
 */


let stop_edgeTOshape_pts = stop_edge_idTOshape_pts(resource: myStaticDict)

writeStopEdge_shapePtsJSON(stop_edge_idTOshape_pts: stop_edgeTOshape_pts, output: myIO.dictionaryPath+"stopEdge_shapes.json")
writeStopEdge_shapePts(stop_edge_idTOshape_pts: stop_edgeTOshape_pts,
                        output: myIO.dictionaryPath+"stopEdge_shapePts.txt")



//writeStopEdgeTable(resource: myStaticDict, output: myIO.dictionaryPath+"stop_edge_table.txt")
