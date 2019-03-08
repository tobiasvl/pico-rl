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
 radio=0
 log={}

 seed=rnd(-1)
 srand(seed)

 mobs={}
 player=mob:new{
  name="you",
  c="웃",
  col=9,
  hp=5,
  str=5,
  arm=5,
  move=function(self,move)
   local x=self.x+dirs[move][1]
   local y=self.y+dirs[move][2]
   if iswalkable(x,y,"corridor") then
    local move=true
    for m in all(mobs) do
     if m.x==x and m.y==y then
      move=false
      attack(self,m)
     end
    end
    if (move) self.x,self.y=x,y
   end
  end
 }
 add(mobs,player)

 add(log,"you enter level "..level.." of the tomb")
 add(log,"the walls emanate radioactivity")

 generate_dungeon=gendun_rogue
 dungeon=generate_dungeon(25*level,25*level,3*level,3*level)
 --dungeon=generate_dungeon(20,20,2,2)
 fogmap=generate_fogmap(dungeon.map)

 --generate dummy mobs
 for _=1,7 do
  local x,y
  repeat
   x,y=ceil(rnd(dungeon._width)),ceil(rnd(dungeon._height))
  until dungeon.map[x][y]==0
  add(mobs,tomb_bot:new{x=x,y=y})
 end

 cam={x=-player.x*w+64,y=-player.y*h+60}

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
  {1,1},
  {0,0},
  {0,0},
  {0,0},
  {0,0},
  {0,0}}
end
-->8
--generate dungeon

function gendun_rogue(w, h, gw, gh)
 -- https://web.archive.org/web/20130510010345/http://kuoi.com/~kamikaze/gamedesign/art07_rogue_dungeon.php
 local map={}
 local grid={}
 local rooms={}
 local unconnected={}

 function connect_rooms(r1,r2)
  add(r1.connected_neighbors,r2)
  add(r2.connected_neighbors,r1)
  r1.connected=true
  r2.connected=true
  del(unconnected,r1)
  del(unconnected,r2)
 end

 for x=1,w do
  local col=add(map,{})
  for y=1,h do
   add(col,1)
  end
 end
 --1 2
 for y=1,gh do
  local col=add(grid,{})
  for x=1,gw do
   local room=add(col,{connected=false,neighbors={},connected_neighbors={},gx=x,gy=y})
   add(rooms,room)
   add(unconnected,room)
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
 local room=rooms[ceil(rnd(#rooms))]
 room.connected=true
 del(unconnected,room)
 local start=room

 --4
 ::continue::
 for n in all(room.neighbors) do
  if not n.connected then
   connect_rooms(room,n)
   room=n
   goto continue
  end
 end

 --5
 local goal
 -- this is not very efficient
 while #unconnected>0 do
  for room in all(unconnected) do
   for n in all(room.neighbors) do
    if n.connected then
     connect_rooms(room,n)
     break
    end
   end
  end
 end
 goal=room

 --6
 assert(#unconnected==0)
 for room in all(rooms) do
  assert(room.connected)
 end

 --7
 for _=0,flr(rnd(gw)) do
  local room=rooms[ceil(rnd(#rooms))]
  for n in all(room.neighbors) do
   for n2 in all(room.connected_neighbors) do
    if n==n2 then
     goto next_room
    end
   end
   connect_rooms(room,n)
   break
   ::next_room::
  end
 end

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
    local start={x=room.start_x+flr((room.end_x-room.start_x)/2),y=room.start_y+flr((room.end_y-room.start_y)/2)}
    local goal={x=n.start_x+flr((n.end_x-n.start_x)/2),y=n.start_y+flr((n.end_y-n.start_y)/2)}
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
 dungeon.rooms=rooms
 --dungeon._doors={}
 dungeon.start=start
 return dungeon
end

function generate_fogmap(map)
 local fogmap={}
 for x=1,#map do
  add(fogmap,{})
  for y=1,#map[1] do
   add(fogmap[i],0)
  end
 end
 return fogmap
end

function coords_to_room(x,y)
 for room in all(dungeon.rooms) do
  if x>=room.start_x and x<=room.end_x and y>=room.start_y and y<=room.end_y then
   return room
  end
 end
end

function unfogroom(room)
 if dungeon.map[player.x][player.y]==2 then
  for dir in all(dirs) do --eight or four?
   local x,y=player.x+dir[1],player.y+dir[2]
   if dungeon.map[x][y]==2 or dungeon.map[x][y]==0 then
    fogmap[x][y]=1
   end
  end
  return
 end
 for x=room.start_x-1,room.end_x+1 do
  for y=room.start_y-1,room.end_y+1 do
   fogmap[x][y]=1
  end
 end
end

function fogdungeon()
 for x=1,#dungeon.map do
  for y=1,#dungeon.map[1] do
   if fogmap[x][y]==1 then
    fogmap[x][y]=2
   end
  end
 end
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
  radio+=0.5
  for m in all(mobs) do
   m:move(move)
  end
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
 --print(sub(tostr(seed,true),3),0,0,3)
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

 fogdungeon()
 unfogroom(coords_to_room(player.x,player.y))

 for x=1,dungeon._width do
  for y=1,dungeon._height do
   local c=6
   if fogmap[x][y]==2 then
    c=5
   end
   if fogmap[x][y]==1 or fogmap[x][y]==2 then
    local parts={"█","▒","▤"}
    local part=parts[dungeon.map[x][y]]
    if part then
     print(part,x*w+cam.x,y*h+cam.y,c)
    else
     if (fogmap[x][y]==1) print(".",x*w+cam.x+2,y*h+cam.y-2,5)
    end
   end
  end
 end

 for m in all(mobs) do
  if fogmap[m.x][m.y]==1 then
   rectfill(m.x*w-1+cam.x,m.y*h-1+cam.y,m.x*w-1+w+cam.x,m.y*h-1+h+cam.y,m.bg)
   print(m.c,m.x*w+cam.x,m.y*h+cam.y,m.col)
  end
 end

 drawlog()
 drawhud()
 --print(stat(1),0,0)
end

function drawlog()
 rectfill(0,0,128,h*2-1,0)
 print(#log>1 and log[#log-1] or "",0,0,7)
 print(#log>0 and log[#log] or "",0,h,7)
end

function drawhud()
 local x,y=0,128-h
 rectfill(x,y-2,radio,y-2,11)
 rectfill(radio+1,y-2,128,y-2,0)
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

function iswalkable(x,y,check)
 if y<1 or y>#dungeon.map or x<1 or x>#dungeon.map[1] then
  return false
 end
 if dungeon.map[x][y]==0 then
  return true
 elseif check=="corridor" and dungeon.map[x][y]==2 then
  return true
 else
  return false
 end
end

function dijkstra(fx,fy,tx,ty)
 local dmap={}
 local unvisited={}
 local t
 local room=coords_to_room(fx,fy)
 if (not room or room!=coords_to_room(tx,ty)) return nil
 for x=room.start_x,room.end_x do
  for y=room.start_y,room.end_y do
   dmap[x..","..y]=add(unvisited,{x=x,y=y,value=99,visited=false})
  end
 end

 t=dmap[fx..","..fy]
 t.value=0

 while not dmap[tx..","..ty].visited do
  if (#unvisited==0) return nil
  for dir in all(four) do --eight?
   local nx=t.x+dir[1]
   local ny=t.y+dir[2]
   if iswalkable(nx,ny) and nx>=room.start_x and nx<=room.end_x and ny>=room.start_y and ny<=room.end_y then
    local n=dmap[nx..","..ny]
    n.value=min(t.value+1,n.value)
   end
  end
  t.visited=true
  del(unvisited,t)

  local minimum=99
  for n in all(unvisited) do
   if n.value<minimum then
    t=n
    minimum=n.value
   end
  end
  if (minimum==99) break
 end
 return dmap
end

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
 bg=0,
 hp=0,
 move=function(self)
  local room=coords_to_room(self.x,self.y)
  if (room!=coords_to_room(player.x,player.y)) return
  local dmap=dijkstra(player.x,player.y,self.x,self.y)
  local minimum=99
  local cells={}
  for dir in all(four) do
   local nx,ny=self.x+dir[1],self.y+dir[2]
   local n=dmap[nx..","..ny]
   if n and n.value<minimum then
    add(cells,n)
    minimum=n.value
   end
  end
  local n=cells[#cells]
  if n then
   if n.value==0 then
    attack(self,player)
   else
    self.x,self.y=n.x,n.y
   end
  end
 end,
 new=function(self,o)
  self.__index=self
  o.max_hp=o.hp
  o.max_str=o.str
  return setmetatable(o or {},self)
 end
}

base_mob=mob:new({
 name="mob",
 c="😐",
 hp=1,
})

tomb_bot=base_mob:new({
 name="tomb bot",
 col=7,
 bg=8,
 hp=5,
 str=5,
 arm=5,
})

eye=mob:new({
 name="eye",
 c="☉",
 col=8,
 hp=5,
 str=5,
 arm=5,
})

cat=mob:new({
 c="🐱",
 col=8,
 hp=5,
 str=5,
 arm=5,
})

bat=mob:new({
 c="ˇ",
 col=8,
 hp=5,
 str=5,
 arm=5,
})

function attack(attacker,defender)
 local dmg=1
 defender.hp-=dmg
 add(log,attacker.name.." hit "..defender.name.." for "..dmg.." damage")
 if defender.hp==0 then
  del(mobs,defender)
  add(log,defender.name.." died")
 end
 local ff=f
 for _=ff,ff+1000 do

 end
end
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a00000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a00000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
