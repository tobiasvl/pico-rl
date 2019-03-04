pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--init
function _init()
 poke(0x5f2d,1)

 --draw=title_draw
 --update=title_update

 draw=game_draw
 update=game_update

 t=0
 f=0
 w,h=8,6

 name=nil
 level=1
 gold=0

 mobs={}
 player=mob:new{
  c="웃",
  col=9,
  hp=5,
  str=5,
  arm=5,
  move=function(self,move)
   local x=self.x+dirs[move][1]
   local y=self.y+dirs[move][2]
   if x>0 and x<=dungeon._width and y>0 and y<=dungeon._height then--and dungeon.map[x][y]!=1 then
    self.x,self.y=x,y
   end
  end
 }
 add(mobs,player)

 generate_dungeon=gendun_rogue
 dungeon=generate_dungeon(50,50,4,4)

 --generate dummy mobs
 for _=1,7 do
  add(mobs,mob:new({
   c="😐",
   hp=1,
   x=flr(rnd(dungeon._width)),
   y=flr(rnd(dungeon._height))
  }))
 end

 cam={x=-player.x*w+64,y=-player.y*h+64}

 dirs={
  {-1,0},
  {1,0},
  {0,0},
  {0,-1},
  {-1,-1},
  {1,-1},
  {0,0},
  {0,1},
  {-1,1},
  {1,1}}
end
-->8
--generate dungeon
function gendun_rogue(w, h, gw, gh)
  -- https://web.archive.org/web/20130510010345/http://kuoi.com/~kamikaze/gamedesign/art07_rogue_dungeon.php
  local map={}
  for x=1,w do
    local col=add(map,{})
    for y=1,h do
      add(col,1)
    end
  end
  --1 2
  local grid={}
  for y=1,gh do
    local col=add(grid,{})
    for x=1,gw do
      add(col,{connected=false,neighbors={},connected_neighbors={}})
    end
  end

  for y=1,gh do
    for x=1,gw do
      local room=grid[y][x]
      for i in all(four) do
        local ny=y+i[2]
        local nx=x+i[1]
        if ny>0 and ny<=gh and nx>0 and nx<=gw then
          add(room.neighbors,grid[ny][nx])
        end
      end
      room.neighbors=shuffle(room.neighbors)
    end
  end

  --3
  local gy=flr(rnd(#grid))+1
  local gx=flr(rnd(#grid[1]))+1
  local room=grid[gy][gx]
  room.connected=true
  local start=room
  printh("starting with "..gx..","..gy)

  --4
  ::continue::
  for n in all(room.neighbors) do
    if not n.connected then
      add(room.connected_neighbors,n)
      add(n.connected_neighbors,room)
      room.connected=true
      n.connected=true
      room=n
      goto continue
    end
  end

  --5
  local goal
  do
    local room
    for y=1,gh do
      for x=1,gw do
        room=grid[y][x]
        if not room.connected then
          for n in all(room.neighbors) do
            printh("unconnected, attempting to connect "..x..","..y)
            if n.connected then
              add(room.connected_neighbors,n)
              add(n.connected_neighbors,room)
              room.connected=true
              n.connected=true
              printh("connected")
              break
            end
          end
        end
      end
    end
    goal=room
  end

  --6
  for y=1,gh do
    for x=1,gw do
      if not grid[y][x].connected then
        printh("STILL UNCONNECTED: "..x..","..y)
      end
    end
  end

  --7

  --8 carve
  for y=1,gh do
    for x=1,gw do
      local room=grid[y][x]
      local r=flr(rnd(3))
      room.start_y=(y-1)*flr(h/gh)+2+r
      room.end_y=y*flr(h/gh)-r
      room.start_x=(x-1)*flr(w/gw)+2+r
      room.end_x=x*flr(w/gw)-r
      for yy=room.start_y,room.end_y do
        for xx=room.start_x,room.end_x do
          map[xx][yy]=0
        end
      end
    end
  end
  -- carve corridors
  for y=1,gh do
    for x=1,gw do
      local room=grid[y][x]
      for n in all(room.connected_neighbors) do
        local start={x=room.start_x+(room.end_x-room.start_x)/2,y=room.start_y+(room.end_y-room.start_y)/2}
        local goal={x=n.start_x+(n.end_x-n.start_x)/2,y=n.start_y+(n.end_y-n.start_y)/2}
        --start={x=flr(rnd(room.end_x-room.start_x))+room.start_x+1,y=flr(rnd(room.end_y-room.start_y))+room.start_y+1}
        --goal={x=flr(rnd(n.end_x-n.start_x))+n.start_x+1,y=flr(rnd(n.end_y-n.start_y))+n.start_y+1}
        local dir_x=sgn(goal.x-start.x)
        local dir_y=sgn(goal.y-start.y)

        --local yy=start.y
        --for xx=start.x,goal.x,dir_x do
        --  if (map[xx][yy]==1) map[xx][yy]=2
        --  map[xx][yy]=2
        --end
        --local xx=start.x
        --for yy=start.y,goal.y,dir_y do
        --  if (map[xx][yy]==1) map[xx][yy]=2
        --  map[xx][yy]=2
        --end
        -- change to pathfinding
        for xx=start.x,goal.x,dir_x do
          for yy=start.y,goal.y,dir_y do
            if (map[xx][yy]==1) map[xx][yy]=2
          end
        end
      end
    end
  end

  --9 doors

  --10 stairs
  assert(start!=goal)
  do
    local x=flr(rnd(start.end_x-start.start_x)+start.start_x)+1
    local y=flr(rnd(start.end_y-start.start_y)+start.start_y)+1
    map[x][y]=3
    player.x=x
    player.y=y
  end
  do
    local x=flr(rnd(goal.end_x-goal.start_x)+goal.start_x)+1
    local y=flr(rnd(goal.end_y-goal.start_y)+goal.start_y)+1
    map[x][y]=3
  end

  local dungeon={}
  dungeon._width=w
  dungeon._height=h
  dungeon.map=map
  dungeon.grid=grid
  dungeon._doors={}
  return dungeon
end

-->8
--update
function _update()
 f+=1
 update()
end

function title_update()
 if f>=30 then
  if btnp(❎) and not name then
   name=""
  elseif name then
   if stat(30) then
    local str=stat(31)
    if str=="\b" then
     name=sub(name,1,-2)
    elseif str=="\r" then
     poke(0x5f30,1)
     update=game_update
     draw=game_draw
    elseif str!="\t" then
     if (str=="p") poke(0x5f30,1)
     if (#name<=23) name=name..str
    end
   end
  end
 end
end

function game_update()
 local move=btnp()
 if move>0 and move<15 then
  t+=1
  for m in all(mobs) do
   m:move(move)
  end
 end
 if move==0x10 then
   cam.x-=8
 elseif move==0x20 then
   cam.y-=8
 end

 --scroll
 if (player.x+cam.x/w>13) cam.x-=w
 if (player.x+cam.x/w<2) cam.x+=w
 if (player.y+cam.y/h>16) cam.y-=h
 if (player.y+cam.y/h<2) cam.y+=h
end
-->8
--draw
function _draw()
 draw()
end

function title_draw()
 cls()
 for i=0,min(f/10,3) do
  print("pirogue",64-(5*4)/2+i,i,8)
 end
 if f>=30 then
  print("pirogue",64-(5*4)/2+3,3,10)
  print("☉☉",30,20,11)
  print("☉☉",20,40,11)
  print("☉☉",40,35,11)
  print("∧ ∧",70,20,10)
  print([[   _
  | |
 /___\]],67,26,12)
  print("◆",77,25,8)
  print("웃",77,32,9)
 end

 if f>=30 and not name then
  center("press ❎",64,5)
 elseif name then
  center("name:",64,5)
  print(name.."_",25,72,7)
 end
end

function game_draw()
 cls()

--[[
 for coords,item in pairs(dungeon) do
  print(item,coords[1]*w+cam.x,coords[2]*h+cam.y,6)
 end
]]

 for x=1,dungeon._width do
  for y=1,dungeon._height do
   local item=dungeon.map[x][y]
   if item==1 then
    print("█",x*w+cam.x,y*h+cam.y,6)
   elseif item==2 then
    print("▒",x*w+cam.x,y*h+cam.y,6)
  elseif item==3 then
    print("▤",x*w+cam.x,y*h+cam.y,6)
   else
    print(".",x*w+cam.x+2,y*h+cam.y-2,5)
   end
  end
 end

 for d in all(dungeon._doors) do
   print("++",d.x*w+cam.x,d.y*h+cam.y)
 end

 for m in all(mobs) do
  print(m.c,m.x*w+cam.x,m.y*h+cam.y,m.col)
 end

 drawhud()
end

function drawhud()
 local x,y=0,128-h
 rectfill(x,y-1,128,128,0)

 local hud={
  {"l"..level,7},
  {"♥"..player.hp.."/"..player.max_hp,8},
  {"∧"..player.str.."/"..player.max_str,12},
  {"★"..gold,10},
  {"▒"..player.arm,6}
 }

 for h in all(hud) do
  print(h[1],x,y,h[2])
  x+=#h[1]*4+8
 end

 local t_hud="⧗"..t
 print(t_hud,128-#t_hud*4-4,128-h,7)
end
-->8
--tools

function getrandomint(min, max)
    min=min and min or 0
    max=max and max or 1
    return flr(rnd(max))+min
end

function shuffle(t)
  for n=1,#t*2 do -- #t*2 times seems enough
    local a,b=flr(1+rnd(#t)),flr(1+rnd(#t))
    t[a],t[b]=t[b],t[a]
  end
  return t
end
four={
                { 0,-1},
                { 1, 0},
                { 0, 1},
                {-1, 0}
               }
eight={
    { 0,-1},
    { 1,-1},
    { 1, 0},
    { 1, 1},
    { 0, 1},
    {-1, 1},
    {-1, 0},
    {-1,-1}
   }
function center(str,y,c)
 if (c) color(c)
 print(str,64-#str/2,y)
 if (c) color()
end

function contains(t,e)
 for i in all(t) do
  if i==e then
   return true
  end
 end
 return false
end

function round(x)
  if x%2 ~= 0.5 then
    return flr(x+0.5)
  end
  return x-0.5
end
-->8
-- mob
mob={
 c="",
 col=8,
 hp=0,
 move=function(self)
  local f={1,2,4,5,6,8,9,10}
  r=ceil(rnd(#f))
  local m=dirs[f[r]]
  x=self.x+m[1]
  y=self.y+m[2]
  if x>0 and x<=dungeon._width and y>0 and y<=dungeon._height and dungeon.map[x][y]!=1 then
   self.x,self.y=x,y
  end
 end,
 new=function(self,o)
  self.__index=self
  o.max_hp=o.hp
  o.max_str=o.str
  return setmetatable(o or {},self)
 end
}
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a00000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a00000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
