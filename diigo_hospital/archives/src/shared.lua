HOSPITAL = { 
    tempDie = 5,
    tempRespawn = 5,
    tempFulDie = 30,
    Object = {
        Id = 1654, -- Id Objeto
        config = {25, -0.03,-0.22,0.1,75.6,-111.6,3.6}, -- ConfiguraC'C#o do pAttach
        Scale = 1 -- Tamanho do objeto
    },
    Tratament = {
        Positions = {
            [1] = {
                {2060.806, -1434.694, 25.558, -0, 0, 0},
                {2058.166, -1433.088, 25.495, -0, 0, 0},
                {2063.37, -1435.918, 25.557, -0, 0, 0},
                {2065.922, -1437.639, 25.55, -0, 0, 0},
            },
        },
        Objects = { -- ID, X, Y, Z, RX, RY, RZ
            {1997, 1156.428, -1338.264-0.3, 16.023-1.55, -0, 0, 89.73567199707},
            {1997, 1156.595-0.3, -1341.947, 16.029-1.55, -0, 0, 90.338447570801},
            {1997, 1156.152-0.3, -1353.626, 16.0230 - 1.55, -0, 0, 90.338447570801},
            {1997, 1156.03-0.3, -1349.972, 16.029-1.55, -0, 0, 90.338447570801},
        },
        Markers = {
            {2044.372, -1415.035, 24.521, 1}
        },
        time = 6, -- Segundos para receber o tratamento (de 6 em 6 segundos atC) encher a vida)
        price = 250,
    }
}

getMedics = function ()
    local count = 0
    for i,v in ipairs(getElementsByType('player')) do 
        if getElementData(v, 'paramedic >> duty') then 
            count = count + 1
        end
    end
    return count
end