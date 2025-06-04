#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SendMode Event  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
WinGet, mainId,,Nova Empire
CoordMode, Pixel, Window
CoordMode, Mouse, Window

Gui, Add, Button, w300 h100 gstartfarm, Start Farming
Gui, Add, Button, w100 h33, Stop
Gui, Show, w320 h150,Pirate Farmer
#Include C:\AutoScript\base.ahk


global Fleet_Assignments := {}

global BottomY := 2170
global RightX := 3850
global LeftX := 11
global TopY := 11
global blacklist := []

global IconDescX1 := 972
global IconDescY1 := 702
global IconDescX2 := 2153 ;coordinates to scan for backup checks for (pirate fleet, elite, etc)
global IconDescY2 := 1334

global Pirate := 0xFF6F00
global pirate_seperation := {"x": 100, "y": 100}
global max_distance := (pirate_seperation["x"] + pirate_seperation["y"])/2
global mainId

global failed := []
global new_failed := []

CustomClick(X, Y, sleep_amount=0)
{
    if (X and Y)
    {
        WinActivate, ahk_id %mainId%
        MouseMove, %X%, %Y%, 0
        Click, %X% %Y%
        Sleep sleep_amount
    }

    Return

}


WithinVariation(PirateShade, CoordColor, variation := 3)
{
    vred := (CoordColor & 0xFF), vgreen := ((CoordColor & 0xFF00) >> 8),vblue := ((CoordColor & 0xFF0000) >> 16)
    tred := (PirateShade & 0xFF), tgreen := ((PirateShade & 0xFF00) >> 8),tblue := ((PirateShade & 0xFF0000) >> 16)
    red_diff := Abs(vred-tred), green_diff := Abs(vgreen-tgreen), blue_diff := Abs(vblue-tblue)

    if (red_diff <= variation and green_diff <= variation and blue_diff <= variation)
    {
        return true
    }
    return False

}

CheckAfterClick(PirateCoords, key)
{

    WinActivate, ahk_id %mainId%
    ImageSearch, PirateX, PirateY, 1000, 900, 1714, 1083, *15 *Trans130F10 *TransBlack *TransWhite C:\AutoScript\images\pirate_fleet.png
    if (ErrorLevel = 0)
    {
        return true
    }
    ImageSearch, EliteX, EliteY, 1000, 900, 1714, 1083, *15 *Trans130F10 *TransBlack *TransWhite C:\AutoScript\images\elite.png
    if (ErrorLevel = 0)
    {
        return true
    }

    rogue_point := False
    speed_mistake := False
    PixelSearch, WindowX, WindowY, 1501, 997, 1567, 1052, 0x1793DF, 5 , Fast RGB ; blue of target names
    if (ErrorLevel = 1)
    {
        ImageSearch, OutputVarX, OutputVarY, 905, 78, 1416, 191, *10 *Trans253439 C:\AutoScript\images\speed.png
        if (ErrorLevel = 0)
        {
            speed_mistake := true
        } else {
            rogue_point := true ; clicked on nothing instead of a fleet or thing
        }
        
    }


    CustomClick(253, 137, 1600)
    ImageSearch, BackX, BackY, 25, 61, 406, 221, *10 C:\AutoScript\images\back_try.png
    if (ErrorLevel = 0)
    {
        CustomClick(253, 137, 1600)
        rogue_point := False
    }
    return False

}
start := True
StartUp()
{
    global start
    WinActivate, ahk_id %mainId%
    WinMaximize, ahk_id %mainId%

    ImageSearch, SystemX, SystemY, LeftX, TopX, RightX, BottomY,*TransWhite *TransBlack *50 C:\AutoScript\images\system_icon.png
    if (SystemX and SystemY)
    {
        CustomClick(SystemX, SystemY, 4000)
    }
    
    if (start == False)
    {
        CustomClick(3817, 1104, 2000)
        CustomClick(3781,585, 2000)
        CustomClick(2951, 283, 2000)
        CustomClick(1940,1812, 6000)
        CustomClick(239, 125, 1500)
    }
    MouseMove, 1900, 50, 1
    MouseClickDrag, L, 1900, 50, 1900, 1801, 2
    
    Loop, 20
    {
        sleep 100
        Click, WheelDown
    }

    sleep 500
    start := False
}

RandomizeArray(array)
{
    new_array := []
    copied_array := array
    old_max := copied_array.MaxIndex()
    while not new_array.MaxIndex() = old_max
    {
        Random, n, 1, copied_array.MaxIndex()
        new_array.Push(copied_array.RemoveAt(n))
    }

    return new_array
}


VerifyData(data, data_key)
{

    split_data := data[data_key]

    split_data := RandomizeArray(split_data)
    Last := {}

    New_Data := []
    things := []

    for key1, coord1 in split_data
    {
        for key2, coord2 in split_data
        {
            if (not key2 = key1 and not coord1 = coord2)
            {
                abs_x := abs(coord1["x"] - coord2["x"])
                abs_y := abs(coord1["y"] - coord2["y"])
                if (abs_x > max_distance or abs_y > max_distance) ; if they arent the same and both x and y are within x pixels choose the first coord
                {
                    accept_key1 := (not things.HasKey(key1)) or (things.HasKey(key1) and not things[key1] = False)
                    if accept_key1
                        things[key1] := true
                    accept_key2 := (not things.HasKey(key2)) or (things.HasKey(key2) and not things[key2] = False)
                    if accept_key2
                        things[key2] := true
                } else {

                    one_scanned := things.HasKey(key1) or things.HasKey(key2)
                    one_true := one_scanned and (things[key1] = true or things[key2] = true)
                    both_scanned := things.HasKey(key1) and things.HasKey(key2)
                    both_true := both_scanned and things[key1] = true and things[key2] = true


                    keys := [key1, key2]
                    Random, NumberVar, 1,2
                    other := key1 = keys[NumberVar] ? key2 : key1
                    if (both_scanned and both_true) 
                    {
                        things[keys[NumberVar]] := False
                    }

                    if (not both_scanned and not one_true)
                    {
                        
                        things[keys[NumberVar]] := true
                        things[other] := False
                    }

                    if (one_scanned and one_true and not both_scanned)
                    {
                        false_value := things.HasKey(key1) ? key2 : key1
                        things[false_value] := False
                    }
                    
                }
            }

        
        }
    }
    for key, value in things
    {
        if (value = true and split_data.HasKey(key))
            New_Data.Push(split_data[key])
    }
    return New_Data


}

ScanPirateSystem(x1 := 11, y1 := 11, x2 := 2000, y2 := 2000, var := 0xFF6F00)
{
    WinActivate, ahk_id %mainId%
    WinMaximize, ahk_id %mainId%
    starting_time := A_TickCount
	; found coordinates are returned as a simple array of coordinate pairs
	; each coordinate pair is an associative array with keys "x" and "y"
    
	found := {"scan": []}
    loop_data := {"x": 100, "y": 100}
    

    second_x := x1 + loop_data["x"]
    first_x := x1


    coord_check_x := x2
    i := 0

    loop {
        i += 1
        PixelSearch, CheckX, CheckY, first_x, y1, coord_check_x, y2, %var%, 2, Fast RGB

        if (not ErrorLevel = 1)
            coord_check_x := coord_check_x / 2
        if (ErrorLevel = 1)
        {
            closest_pixel := coord_check_x
            columns := closest_pixel / loop_data["x"]

            skip_amount := Floor(columns)
            second_x += loop_data["x"] * skip_amount
            first_x += loop_data["x"] * skip_amount
            Break
        }

        if (i = 13)
        {
            Break
        }
    }
    failed_searches := 0
    loop { ; loop through x coordinate intervals and if it finds a scan, scan lower y to find more pirates in same column
        ;WinActivate, ahk_id %mainId%
        PixelSearch, FirstX, FirstY, first_x, y1, second_x, y2, %var%, 2, Fast RGB
        
        if (ErrorLevel = 0)
        {
            failed_searches := 0
            altered_y := FirstY
            found["scan"].Push({"x": FirstX, "y": FirstY})
                
            loop {
                altered_y := altered_y + loop_data["y"]
                ;WinActivate, ahk_id %mainId%
                PixelSearch, ResultX, ResultY, first_x, altered_y, second_x, y2, %var%, 2, Fast RGB

                if (not ErrorLevel = 0 or altered_y >= y2)
                {
                    first_x += loop_data["x"]
                    second_x += loop_data["x"]
                    Break
                }

                if (ErrorLevel = 0)
                {
                    found["scan"].Push({"x": ResultX, "y": ResultY})
                    altered_y := ResultY
                }

            }
        } else {
            failed_searches += 1
            first_x += loop_data["x"]
            second_x += loop_data["x"]

            if (failed_searches >= 3)
            {
                PixelSearch, FirstX, FirstY, first_x, y1, x2, y2, %var%, 2, Fast RGB

                if (ErrorLevel = 1)
                {
                    Break
                }
            }
        }

        if (first_x >=  x2)
        {
            Break
        }

    }
    filtered := VerifyData(found, "scan")
    end_time := A_TickCount
    end_time := (end_time - starting_time)/1000


	return filtered

}

check_logged_out(value := true)
{
    ImageSearch, OutX, OutY, 1069, 848, 2791, 1356, *4 C:\AutoScript\images\disconnected.png
    if (ErrorLevel = 0)
    {
        if (value = true)
        {
            sleep 120000
            CustomClick(1938,1552,5000)
            StartUp()
        }

        Return true
    } else {
        Return false
    }


}


Prune_Failed_Data(PirateCoords)
{

    new_data := PirateCoords
    for key, cord in PirateCoords
    {
        for entry, fail_cord in failed
        {
            abs_x := Abs(cord["x"]-fail_cord["x"])
            abs_y := Abs(cord["y"]-fail_cord["y"])
            if (abs_x <= pirate_seperation["x"] and abs_y <= pirate_seperation["y"])
            {
                new_data[key] := new_failed[entry]
            }
        }

    }

    for key, coord in failed.Clone()
    {
        present := False
        for entry, pirate_coord in PirateCoords
        {
            abs_x := Abs(coord["x"]-pirate_coord["x"])
            abs_y := Abs(coord["y"]-pirate_coord["y"])
            if (abs_x <= pirate_seperation["x"] and abs_y <= pirate_seperation["y"])
                present := true

        }

        if (present = False)
        {
            failed.RemoveAt(key)
            new_failed.RemoveAt(key)
        }

    }

    return new_data

}

FleetScreen(PirateCoord)
{

    fleet_xcoord := {"1": 845, "2": 1380, "3": 1910, "4": 2440, "5": 2970, "6": 3504}
    free := {}
    fleet_distance := []
    WinActivate, ahk_id %mainId%
    for fleet, value in fleet_xcoord
    {
        FirstX := value - 500
        fleet_num := Round(fleet/1, 0)
        
        PixelSearch, IdleX, IdleY, FirstX, 490, value, 545,0x99BE3F,1, Fast RGB
        if (ErrorLevel = 0)
        {
            free[fleet_num] := {"x": IdleX, "y": IdleY}
        }
        
        if (free[fleet_num] and free.HasKey(fleet_num))
        {
            distance := Fleet_Assignments.hasKey(fleet_num) and Fleet_Assignments[fleet_num].HasKey("x") ? Sqrt((PirateCoord["x"] - Fleet_Assignments[fleet]["x"])**2 + (PirateCoord["y"] - Fleet_Assignments[fleet]["y"])**2 ) : False

            fleet_distance[fleet_num] := distance
        }
    }
    chosen := []
    last_value := []
    for fleet, distance in fleet_distance
    {
        last_value := IsObject(last_value) ? distance : last_value
        chosen := IsObject(chosen) ? fleet : chosen

        if (last_value > distance)
        {
            chosen := fleet
            last_value := distance
        }
        if (not Fleet_Assignments.HasKey(fleet))
        {
            Fleet_Assignments[fleet] := {}
        }

        Fleet_Assignments[fleet]["free"] := true
    }
    checked_pirate := False
    if (free.Length() = 0)
    {
        WinActivate, ahk_id %mainId%
        loop
        {
            
            
            PixelSearch, IdleX, IdleY, 345, 490, 3504, 545,0x99BE3F,1, Fast RGB
            if (ErrorLevel = 0)
            {
                FleetScreen(PirateCoord)
                Break
                
            }
            if (ErrorLevel = 1)
            {
                if (checked_pirate = False)
                {
                    PixelSearch, AlertX, AlertY, LeftX, TopY, RightX, BottomY,0x820101,1, Fast RGB
                    checked_pirate := true
                    if (ErrorLevel = 0 and AlertX)
                    {
                        CustomClick(2330, 1700, 1500)
                        FleetScreen(PirateCoord)
                        Break
                    } else {
                        if (check_logged_out(false) = true)
                        {
                            Return
                        }
                    }
                }
            }
            sleep 5000
        }
    }
    
    
    if (not chosen = 0)
    {
        fleet_num := Round(chosen/1, 0)
        CustomClick(free[chosen]["x"], free[chosen]["y"], 755)
        Fleet_Assignments[fleet_num] := PirateCoord
        Fleet_Assignments[fleet_num]["free"] := False
    }
    

}


first := False
startfarm:

    if (first = true)
    {
        StartUp()
        first_loop := true
        i := 0
        loop
        {
            PirateCoords := ScanPirateSystem(LeftX, TopY, RightX, BottomY, Pirate)

            PirateCoords := Prune_Failed_Data(PirateCoords)
            for key, coords in PirateCoords
            {

                PirateX := coords["x"]
                PirateY := coords["y"]

                WinActivate, ahk_id %mainId%
                PixelGetColor, CoordColor, PirateX, PirateY, RGB
                PirateShade := "0xFF6F00"
                shade_valid := WithinVariation(PirateShade, CoordColor, 4)

                close_to_target := False
                for fleet, coord in Fleet_Assignments
                {
                    if (not coord = 0 and coord.HasKey("x"))
                    {
                        abs_x := Abs(PirateX-coord["x"])
                        abs_y := Abs(PirateY-coord["y"])
                        if (abs_x <= pirate_seperation["x"] and abs_y <= pirate_seperation["y"] and coord["free"] = False)
                        {
                            close_to_target := true
                        }
                    }

                }

                blacklisted := False
                for entry, blacklisted_coord in blacklist
                {
                    abs_x := Abs(PirateX - blacklisted_coord["x"])
                    abs_y := Abs(PirateY - blacklisted_coord["y"])

                    if (abs_x <= 8 and abs_y <= 8)
                        blacklisted := true
                }

                if (close_to_target = true or shade_valid = false or blacklisted = true)
                {
                    if (check_logged_out() = true)
                    {
                        Break
                    }
                    Continue
                }

                
                CustomClick(PirateX, PirateY, 1000)
                WinActivate, ahk_id %mainId%
                working := CheckAfterClick(PirateCoords, key)
                if (working = true)
                {
                    CustomClick(2519, 574, 900)
                    FleetScreen(coords)

                } else {
                    Continue
                }


            }
        }


    } else {
        first := true
    }
    

    


Return

GuiExit:
    ExitApp

Esc::ExitApp

F1::Reload