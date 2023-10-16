local component = require("component")
local term = require("term")
local gpu = require("component").gpu
serialization = require("serialization")
local process = require("process")

gpu.freeAllBuffers()

process.info().data.signal = function() 
    gpu.setActiveBuffer(0) 
    os.exit()
end

camPos = {0, 0, -7}
scale = 1.6*50
local offset = {}
offset.x = 80
offset.y = 25

--Drawing Stuff
function drawLine(x0, y0, x1, y1)
    dx = math.abs(x1 - x0)
    dy = math.abs(y1 - y0)
    if x1 > x0 then
        sx = 1
    else
        sx = -1
    end
    if y1 > y0 then
        sy = 1
    else
        sy = -1
    end
    err = dx - dy
    while x0 ~= x1 or y0 ~= y1 and 200 > x0 and 200 > y0 and x0 > -50 and y0 > -50 do
        gpu.set(x0, y0, "  ")
        e2 = 2*err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end
function TDTTD(point, txyz)
    local object = {}
    if txyz ~= nil then
        --print(serialization.serialize(txyz))
        object = {(point[1] + txyz[1]) - camPos[1], (point[2] + txyz[2]) - camPos[2], (point[3] + txyz[3]) - camPos[3]}
    else
        object = {point[1] - camPos[1], point[2] - camPos[2], point[3] - camPos[3]}
    end
    local screenPoint = {}
    screenPoint.x = ((object[1]/object[3])*scale)*2 + offset.x
    screenPoint.y = ((object[2]/object[3])*scale) + offset.y
    return screenPoint
end
function drawEdge(edge, obj)
    --print("drawEdge")
    --print(serialization.serialize(obj))
    local pointA = {}
    local pointB = {}
    if obj == nil then
        pointA = TDTTD(vertice[edge[1]])
        pointB = TDTTD(vertice[edge[2]])
    else
        pointA = TDTTD(vertice[edge[1]], obj.origin)
        pointB = TDTTD(vertice[edge[2]], obj.origin)
    end
    if ((160 > pointA.x and 160 > pointB.x) and (pointA.x > 0 and pointB.x > 0)) and ((50 > pointA.y and 50 > pointB.y) and (pointA.y > 0 and pointB.y > 0)) then
        drawLine(math.floor(pointA.x), math.floor(pointA.y), math.floor(pointB.x), math.floor(pointB.y))
    end
end

--Rotation Stuff

function multMatrix(matrixA, matrixB)
    return {matrixB[1]*matrixA[1][1] + matrixB[2]*matrixA[1][2], matrixB[1]*matrixA[2][1] + matrixB[2]*matrixA[2][2]}
end
function rotateX(vName, angle)
    angle = math.rad(angle)
    local point = vertice[vName]
    local newYZ = multMatrix({{math.cos(angle), math.sin(angle)}, {-math.sin(angle), math.cos(angle)}}, {point[2], point[3]})
    vertice[vName] = {point[1], newYZ[1], newYZ[2]}
end
function rotateY(vName, angle)
    angle = math.rad(angle)
    local point = vertice[vName]
    local newYZ = multMatrix({{math.cos(angle), math.sin(angle)}, {-math.sin(angle), math.cos(angle)}}, {point[1], point[3]})
    vertice[vName] = {newYZ[1], point[2], newYZ[2]}
end
function rotateZ(vName, angle)
    angle = math.rad(angle)
    local point = vertice[vName]
    local newYZ = multMatrix({{math.cos(angle), math.sin(angle)}, {-math.sin(angle), math.cos(angle)}}, {point[1], point[2]})
    vertice[vName] = {newYZ[1], newYZ[2], point[3]}
end
function rotateObject(obj, angle)
    for k, v in pairs(obj.vertices) do
        rotateX(k, angle[1])
        rotateY(k, angle[2])
        rotateZ(k, angle[3])
    end
end

--Translation Stuff

function translate(vName, xyz)
    local point = vertice[vName]
    vertice[vName] = {(point[1] + xyz[1]), (point[2] + xyz[2]), (point[3] + xyz[3])}
end
function translateObject(obj, xyz)
    obj.origin = {obj.origin[1] + xyz[1], obj.origin[2] + xyz[2], obj.origin[3] + xyz[3]}
end

--Render Stuff

function drawObject(obj, color)
    --print("Draw OBJ")
    gpu.setActiveBuffer(gpu.allocateBuffer())
    gpu.setBackground(color)
    --print("Gpu stuff")
    for k, v in pairs(obj.edges) do
        --print("AHHHHH")
        drawEdge(v, obj)
    end
    --print("We Made It!")
    gpu.bitblt(0, 1, 1, 180, 50, gpu.getActiveBuffer(), 1, 1)
    gpu.freeAllBuffers()
end

vertice = {}
edge = {}

vertice.A = {1, 1, 1}
vertice.B = {-1, 1, 1}
vertice.C = {-1, -1, 1}
vertice.D = {1, -1, 1}
vertice.E = {1, 1, -1}
vertice.F = {-1, 1, -1}
vertice.G = {-1, -1, -1}
vertice.H = {1, -1, -1}

vertice.I = {0.5, 0.5, 0.5}
vertice.J = {-0.5, 0.5, 0.5}
vertice.K = {-0.5, -0.5, 0.5}
vertice.L = {0.5, -0.5, 0.5}
vertice.M = {0.5, 0.5, -0.5}
vertice.N = {-0.5, 0.5, -0.5}
vertice.O = {-0.5, -0.5, -0.5}
vertice.P = {0.5, -0.5, -0.5}

edge.AB = {"A", "B"}
edge.BC = {"B", "C"}
edge.CD = {"C", "D"}
edge.DA = {"D", "A"}
edge.EF = {"E", "F"}
edge.FG = {"F", "G"}
edge.GH = {"G", "H"}
edge.HE = {"H", "E"}
edge.AE = {"A", "E"}
edge.BF = {"B", "F"}
edge.CG = {"C", "G"}
edge.DH = {"D", "H"}

edge.IJ = {"I", "J"}
edge.JK = {"J", "K"}
edge.KL = {"K", "L"}
edge.LI = {"L", "I"}
edge.MN = {"M", "N"}
edge.NO = {"N", "O"}
edge.OP = {"O", "P"}
edge.PM = {"P", "M"}
edge.IM = {"I", "M"}
edge.JN = {"J", "N"}
edge.KO = {"K", "O"}
edge.LP = {"L", "P"}

edge.AI = {"A", "I"}
edge.BJ = {"B", "J"}
edge.CK = {"C", "K"}
edge.DL = {"D", "L"}
edge.EM = {"E", "M"}
edge.FN = {"F", "N"}
edge.GO = {"G", "O"}
edge.HP = {"H", "P"}

objects = {}

objects.A = {}
objects.A.vertices = vertice
objects.A.edges = edge
objects.A.origin = {0, 0, 0}

while true do
    gpu.setBackground(0x000000)
    --term.clear()
    --translateObject(objects.A, {0.05, 0, 0})
    rotateObject(objects.A, {2, 2, 2})
    drawObject(objects.A, 0x5eb31)
    os.sleep(0.1)
end
