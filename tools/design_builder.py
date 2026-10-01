"""Rebuild self-contained SVG artboards, clickable design preview and native Figma scenes.
No web services or API tokens required. Run from the project root with Python 3.
"""
from pathlib import Path
import base64, json, html, copy, re
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'design'; (D/'screens').mkdir(exist_ok=True); (D/'figma-plugin').mkdir(exist_ok=True)
C={'ink':'#18221c','green':'#2c6b4b','sage':'#eaf2e8','background':'#f7f8f5','muted':'#68736b','line':'#e7ebe4','blue':'#496b88','blueLight':'#edf2f7','white':'#ffffff'}
assets={k:base64.b64encode((ROOT/v).read_bytes()).decode() for k,v in {
 'hero':'assets/images/campus_car.jpg','aarav':'assets/avatars/aarav.jpg','ananya':'assets/avatars/ananya.jpg','rohan':'assets/avatars/rohan.jpg'}.items()}
font=base64.b64encode((ROOT/'assets/fonts/Manrope.ttf').read_bytes()).decode()
logo=(ROOT/'assets/svg/logo.svg').read_text()
map_svg=(ROOT/'assets/svg/campus_map.svg').read_text()
def ico(name,color=C['ink']):
 paths={
 'arrow':'<path d="M4 12h16m-6-6 6 6-6 6"/>',
 'back':'<path d="M20 12H4m6-6-6 6 6 6"/>',
 'search':'<circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/>',
 'person':'<circle cx="12" cy="7" r="3.2"/><path d="M5 21v-3c0-4 14-4 14 0v3z"/>',
 'people':'<circle cx="9" cy="7" r="3"/><path d="M3 20v-3c0-4 12-4 12 0v3zM17 5a3 3 0 0 1 0 6m1 3c2 0 3 1 3 3v3"/>',
 'car':'<path d="M4 10l2-6h12l2 6v10h-3v-3H7v3H4zM4 10h16M7 14h2m6 0h2"/>',
 'plus':'<circle cx="12" cy="12" r="9"/><path d="M7 12h10m-5-5v10"/>',
 'calendar':'<rect x="4" y="5" width="16" height="16" rx="2"/><path d="M4 10h16M8 3v4m8-4v4"/>',
 'clock':'<circle cx="12" cy="12" r="9"/><path d="M12 6v6l4 2"/>',
 'seat':'<rect x="6" y="3" width="12" height="9" rx="2"/><path d="M4 12v5h16v-5M7 17v4m10-4v4"/>',
 'leaf':'<path d="M21 3C8 3 2 10 5 17s14 3 16-14zM6 18 16 8"/>',
 'bookmark':'<path d="M6 3h12v18l-6-4-6 4z"/>',
 'swap':'<path d="M3 8h17m-4-4 4 4-4 4M21 16H4m4-4-4 4 4 4"/>',
 'chevron':'<path d="m7 9 5 5 5-5"/>',
 'bell':'<path d="M6 16v-5a6 6 0 0 1 12 0v5l2 2H4zM10 21h4"/>',
 'pin':'<path d="M12 22S4 14 4 9a8 8 0 1 1 16 0c0 5-8 13-8 13z"/><circle cx="12" cy="9" r="2.5"/>',
 'check':'<path d="m5 12 4 4 10-10"/>',
 'chat':'<path d="M3 4h18v13H8l-5 4z"/>',
 'close':'<path d="m5 5 14 14M5 19 19 5"/>',
 'shield':'<path d="m12 2 8 4v6c0 5-8 10-8 10S4 17 4 12V6z"/><path d="m8 11 3 3 5-6"/>',
 'send':'<path d="M12 20V4m-6 6 6-6 6 6"/>',
 'school':'<path d="m2 8 10-5 10 5-10 5zM6 11v7l6 3 6-3v-7M22 8v9"/>',
 }
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{paths.get(name,paths["arrow"])}</svg>'
class Scene:
 def __init__(self,id,title,w=390,h=844,bg=None):
  self.id=id;self.title=title;self.w=w;self.h=h;self.nodes=[];self.rect(0,0,w,h,bg or C['background'],r=0,name='Page background')
 def rect(self,x,y,w,h,fill=C['white'],r=14,stroke=None,name=None,nav=None,opacity=1):
  self.nodes.append({'type':'rect','x':x,'y':y,'w':w,'h':h,'fill':fill,'r':r,'stroke':stroke,'name':name or 'Surface','nav':nav,'opacity':opacity});return self
 def text(self,x,y,text,size=13,weight=500,color=None,w=None,align='LEFT',nav=None,lh=None,name=None):
  self.nodes.append({'type':'text','x':x,'y':y,'text':text,'size':size,'weight':weight,'fill':color or C['ink'],'w':w or self.w-x-20,'align':align,'lh':lh or round(size*1.45,1),'nav':nav,'name':name or 'Text / '+text.split('\n')[0]});return self
 def icon(self,x,y,name,color=None,size=20,nav=None):
  self.nodes.append({'type':'svg','x':x,'y':y,'w':size,'h':size,'svg':ico(name,color or C['ink']),'nav':nav,'name':'Icon / '+name});return self
 def image(self,x,y,w,h,key,r=14):
  self.nodes.append({'type':'image','x':x,'y':y,'w':w,'h':h,'asset':key,'r':r,'name':'Image / '+key});return self
 def svg(self,x,y,w,h,value,name='Vector illustration'):
  self.nodes.append({'type':'svg','x':x,'y':y,'w':w,'h':h,'svg':value,'name':name});return self
 def button(self,x,y,w,label,nav,outline=False,h=48):
  self.rect(x,y,w,h,C['white'] if outline else C['ink'],12,C['line'] if outline else None,name='Button / '+label,nav=nav)
  self.text(x+12,y+(h-18)/2-2,label,10 if w<170 else 12,750,C['ink'] if outline else C['white'],w-48,'CENTER',nav,lh=18)
  self.icon(x+w-31,y+(h-17)/2,'arrow',C['ink'] if outline else C['white'],17,nav);return self
 def chip(self,x,y,label,selected=False,nav=None,w=None):
  width=w or max(55,len(label)*6.2+24)
  self.rect(x,y,width,36,C['ink'] if selected else C['white'],10,None if selected else C['line'],nav=nav,name='Filter / '+label)
  self.text(x+11,y+10,label,10,700,C['white'] if selected else C['ink'],width-22,nav=nav,lh=16)
  return width
 def role(self,x,y,driver=True,label=None,w=71):
  fill=C['sage'] if driver else C['blueLight'];color=C['green'] if driver else C['blue']
  self.rect(x,y,w,24,fill,7,name='Role / '+('Driver' if driver else 'Rider'));self.icon(x+7,y+5,'car' if driver else 'person',color,13)
  self.text(x+25,y+5,label or ('Driver' if driver else 'Rider'),9,800,color,w-29,lh=14)
 def header(self):
  self.rect(0,0,self.w,76,C['white'],0);self.rect(0,75,self.w,1,C['line'],0)
  self.svg(20,22,32,32,logo,'Brand / symbol');self.text(62,26,'RideTogether',18,800,w=180,lh=24)
  self.icon(self.w-92,29,'bell',size=19);self.image(self.w-52,23,30,30,'rohan',15)
 def nav(self,selected='find'):
  self.rect(0,772,390,72,C['white'],0,name='Navigation bar');self.rect(0,772,390,1,C['line'],0)
  for i,(key,label,icon,target) in enumerate([('find','Find ride','search','01-find-ride'),('post','Post ride','plus','02-post-route'),('matches','My matches','people','08-my-matches')]):
   cx=65+i*130
   if key==selected:self.rect(cx-32,782,64,27,C['sage'],20,name='Selected tab indicator')
   self.icon(cx-10,786,icon,size=20,nav=target);self.text(i*130,813,label,9,650,w=130,align='CENTER',nav=target,lh=14)
   self.rect(i*130,773,130,71,C['white'],0,name='Hotspot / '+label,nav=target,opacity=0)
 def field(self,x,y,w,label,value,icon=None,h=56):
  self.rect(x,y,w,h,C['background'],12,C['line'],name='Form field / '+label)
  self.text(x+14,y+8,label,9,500,C['muted'],w-28,lh=14)
  if icon:self.icon(x+14,y+30,icon,size=15)
  self.text(x+(38 if icon else 14),y+28,value,12,700,w=w-53 if icon else w-28,lh=18)
 def progress(self,step):
  for i,label in enumerate(['Route','Details','Review']):
   x=20+i*122;active=i<=step
   self.rect(x,198,29,29,C['ink'] if active else C['white'],15,None if active else C['line'],name='Progress step')
   if i<step:self.icon(x+7,205,'check',C['white'],15)
   else:self.text(x,204,'0'+str(i+1),10,800,C['white'] if active else C['muted'],29,'CENTER',lh=15)
   self.text(x+36,204,label,10,700,C['ink'] if active else C['muted'],70,lh=15)
   if i<2:self.rect(x+84,212,28,1,C['line'],0)
 def route(self,x,y,w=300,vertical=True):
  if vertical:
   self.rect(x,y+5,8,8,C['white'],4,C['ink']);self.rect(x+3.5,y+15,1,34,C['line'],0);self.rect(x,y+53,8,8,C['ink'],2)
   self.text(x+22,y,'North Gate',14,750,w=w-22,lh=20);self.text(x+22,y+22,'Greenfield University',10,500,C['muted'],w-22,lh=16)
   self.text(x+22,y+48,'Riverside Metro',14,750,w=w-22,lh=20);self.text(x+22,y+70,'Station entrance · 3.2 km away',10,500,C['muted'],w-22,lh=16)
  else:
   self.rect(x,y+6,8,8,C['white'],4,C['ink']);self.text(x+18,y,'North Gate',13,750,w=160,lh=20)
   self.icon(x+w*.49,y+2,'arrow',C['muted'],16);self.rect(x+w*.57,y+6,8,8,C['ink'],2)
   self.text(x+w*.57+18,y,'Riverside Metro',13,750,w=w*.43-18,lh=20)
 def info(self,x,y,icon,value,w=110,color=None):
  self.icon(x,y,icon,color or C['muted'],14);self.text(x+21,y-1,value,10,600,color or C['muted'],w-21,lh=16)
 def map(self,x,y,w,h):
  self.rect(x,y,w,h,'#f0f2e9',14,name='Map background')
  self.svg(x,y,w,h,map_svg,'Illustrative campus map');self.nodes[-1]['clipRadius']=14
  route=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360"><path d="M114 234H255V90H406" fill="none" stroke="white" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/><path d="M114 234H255V90H406" fill="none" stroke="{C["green"]}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><circle cx="114" cy="234" r="11" fill="white"/><circle cx="114" cy="234" r="6" fill="{C["ink"]}"/><circle cx="406" cy="90" r="11" fill="white"/><circle cx="406" cy="90" r="6" fill="{C["ink"]}"/></svg>'
  self.svg(x,y,w,h,route,'Route / North Gate to Riverside Metro')
 def to_dict(self):return {'id':self.id,'title':self.title,'width':self.w,'height':self.h,'nodes':self.nodes}
scenes=[]
def add(s):scenes.append(s);return s
# Welcome / identity
s=add(Scene('00-welcome','Welcome & campus sign-in',bg=C['white']));s.header()
s.image(20,96,350,205,'hero',20);s.text(20,327,'YOUR CAMPUS, CONNECTED.',9,800,C['green'],lh=15)
s.text(20,354,'Welcome to your\nbetter commute.',31,800,lh=36);s.text(20,444,'Sign in and find people heading your way.',12,500,C['muted'],lh=19)
s.field(20,492,350,'Campus email','ishaan@greenfield.edu');s.field(20,563,350,'Password','••••••••')
s.button(20,641,350,'Sign in','01-find-ride');s.text(20,713,'LOCAL DEMO · Not real authentication',10,700,C['green'],350,'CENTER',lh=16)
s.text(20,743,'No passwords are stored in demo mode.',10,500,C['muted'],350,'CENTER',lh=16)
# Find offers / requests
for requests in (False,True):
 sid='01b-find-requests' if requests else '01-find-ride'
 s=add(Scene(sid,'Find ride requests' if requests else 'Find a ride'));s.header()
 s.text(20,94,'THE CAMPUS COMMUTE, REIMAGINED',9,800,C['green'],lh=14)
 s.text(20,116,'Your campus.\nYour next ride.',32,800,lh=36)
 s.text(20,197,'Skip the solo commute. Go together.',11,500,C['muted'],lh=17)
 s.image(20,229,350,109,'hero',17);s.rect(31,296,205,28,C['white'],8);s.icon(41,303,'leaf',C['green'],13);s.text(62,303,'Better when we go together.',9,750,w=169,lh=14)
 s.rect(20,354,350,130,C['white'],17,C['line']);s.text(36,370,'PICKUP POINT',8,800,C['muted'],150,lh=13);s.text(222,370,'WHERE TO?',8,800,C['muted'],127,lh=13)
 s.text(36,391,'North Gate',12,750,w=135,lh=17);s.icon(177,385,'swap',C['ink'],19);s.text(222,391,'Riverside Metro',12,750,w=129,lh=17)
 s.rect(36,422,318,1,C['line'],0);s.info(36,446,'calendar','Today',100);s.button(218,437,136,'Find rides',sid,h=34)
 s.chip(20,504,'Ride offers',not requests,'01-find-ride',108);s.chip(137,504,'Ride requests',requests,'01b-find-requests',124);s.chip(270,504,'Saved',False,sid,100)
 s.text(20,558,'Rides heading your way',17,800,w=270,lh=23);s.text(291,563,'● LIVE',9,700,C['green'],79,'RIGHT',lh=13)
 s.rect(20,597,350,160,C['white'],18,C['line'],name='Ride card');s.image(37,613,35,35,'ananya' if requests else 'aarav',18)
 s.text(82,613,'Sneha Kapoor' if requests else 'Aarav Sharma',12,800,w=161,lh=18);s.text(82,634,'Looking for a campus ride' if requests else 'Hyundai i20 · White',9,500,C['muted'],195,lh=14)
 s.role(268,616,not requests,w=78);s.route(37,663,316,vertical=False)
 s.info(37,695,'calendar','Today',81);s.info(121,695,'clock','5:40 PM' if requests else '5:30 PM',91);s.info(222,695,'seat','1 needed' if requests else '3 seats left',128)
 s.text(37,728,'₹40 / seat',11,800,C['green'],140,lh=16);s.button(242,719,111,'View request' if requests else 'View ride','06b-request-details' if requests else '06-ride-details',h=32)
 s.nav('find')
# Guided posting branches
for request in (False,True):
 prefix='b' if request else ''; kindlabel='Ride request' if request else 'Ride offer'
 routeid='02b-post-request' if request else '02-post-route';detailid='03b-request-details' if request else '03-post-details';reviewid='04b-request-review' if request else '04-review';postedid='05b-request-posted' if request else '05-posted'
 for step,sid,title in [(0,routeid,'Post / 01 Route · '+kindlabel),(1,detailid,'Post / 02 Details · '+kindlabel),(2,reviewid,'Post / 03 Review · '+kindlabel)]:
  s=add(Scene(sid,title));s.header();s.text(20,94,'A SHARED RIDE STARTS HERE',9,800,C['green'],lh=14)
  s.text(20,115,'A little less solo.\nA lot more together.',26,800,lh=31);s.progress(step)
  s.rect(20,243,350,513,C['white'],19,C['line']);s.text(38,265,'0'+str(step+1)+' / '+['YOUR JOURNEY','THE LITTLE DETAILS','ONE LAST LOOK'][step],9,800,C['green'],lh=14)
  s.text(38,291,['Where are you headed?','Make the ride yours.','Ready to go together?'][step],19,800,lh=25)
  if step==0:
   for i,(driver,label,subtitle,target) in enumerate([(True,'I’m driving','Offer your spare seats','02-post-route'),(False,'I need a ride','Find your campus lift','02b-post-request')]):
    x=38+i*163;chosen=driver!=request;co=C['green'] if driver else C['blue'];bg=C['sage'] if driver else C['blueLight']
    s.rect(x,333,151,100,bg if chosen else C['background'],12,co if chosen else C['line'],nav=target,name='Role choice / '+label)
    s.icon(x+13,347,'car' if driver else 'person',co,23,target);s.text(x+13,382,label,12,800,w=126,nav=target,lh=18);s.text(x+13,405,subtitle,9,500,C['muted'],126,nav=target,lh=14)
   s.field(38,451,314,'Pickup point','North Gate','pin');s.field(38,521,314,'Destination','Riverside Metro','pin')
   s.field(38,591,150,'Departure date','Today','calendar');s.field(201,591,151,'Departure time','5:30 PM','clock')
   s.text(38,663,'Same route. Same day.\nClear pickup details, better connections.',9,500,C['muted'],314,lh=14)
   s.button(38,710,314,'Continue',detailid,h=42)
  elif step==1:
   s.text(38,340,'Seats needed' if request else 'Available seats',13,750,w=185,lh=19);s.text(38,365,'Between 1 and 6 seats',10,500,C['muted'],185,lh=16)
   s.rect(247,337,32,32,C['background'],10,C['line']);s.text(247,344,'−',14,750,w=32,align='CENTER',lh=19);s.text(283,344,'1' if request else '3',15,800,w=28,align='CENTER',lh=19);s.rect(317,337,32,32,C['background'],10,C['line']);s.text(317,344,'+',14,750,w=32,align='CENTER',lh=19)
   s.field(38,405,314,'Suggested contribution / seat' if request else 'Fuel contribution / seat','₹ 40',h=63)
   s.text(38,477,'Optional · ₹0 for free · maximum ₹500',9,500,C['muted'],314,lh=14)
   if not request:s.field(38,506,314,'Vehicle','Hyundai i20 · White','car');s.field(38,579,314,'Pickup note (optional)','Meet by the security booth.',h=68)
   else:s.field(38,506,314,'Pickup note (optional)','Heading to the metro after class.\nA small backpack, and good company.',h=141)
   s.rect(38,663,314,31,C['sage'],9);s.icon(47,671,'check',C['green'],15);s.text(68,671,'I’ll travel responsibly and use seat belts.',9,600,C['green'],271,lh=14)
   s.button(38,710,314,'Continue',reviewid,h=42)
  else:
   s.role(38,329,not request,kindlabel,103);s.route(38,372,314)
   s.rect(38,479,314,1,C['line'],0);s.info(38,503,'calendar','Today',150);s.info(201,503,'clock','5:30 PM',150)
   s.info(38,546,'seat','1 seat needed' if request else '3 seats available',150);s.info(201,546,'leaf','₹40 per seat',150)
   if not request:s.field(38,589,314,'Vehicle','Hyundai i20 · White','car')
   else:s.rect(38,589,314,56,C['blueLight'],12);s.text(52,602,'Your request will appear to drivers\nwith compatible offers.',10,600,C['blue'],280,lh=16)
   s.text(38,663,'No payment is taken.\nConfirm your pickup in match chat.',9,500,C['muted'],314,lh=14)
   s.button(38,710,314,'Publish ride request' if request else 'Publish ride offer',postedid,h=42)
  s.nav('post')
 s=add(Scene(postedid,'Posted / '+kindlabel,bg=C['white']));s.header();s.rect(154,127,82,82,C['sage'],41);s.icon(172,146,'check',C['green'],43)
 s.text(20,247,'YOU’RE ON THE MAP',9,800,C['green'],350,'CENTER',lh=14);s.text(20,278,'Your request is live.' if request else 'Your ride is live.',29,800,w=350,align='CENTER',lh=38)
 s.text(20,336,'One step closer to a better commute.',12,500,C['muted'],350,'CENTER',lh=19);s.rect(20,389,350,184,C['background'],19,C['line']);s.route(40,414,310);s.info(40,523,'calendar','Today',90);s.info(139,523,'clock','5:30 PM',107);s.info(251,523,'seat','1 seat' if request else '3 seats',110)
 s.button(20,622,350,'Find compatible rides' if request else 'Find compatible requests','01-find-ride' if request else '01b-find-requests');s.button(20,687,350,'View my posts','08-my-matches',outline=True)
# Ride detail / request detail
for request in (False,True):
 sid='06b-request-details' if request else '06-ride-details';s=add(Scene(sid,'Connect / Ride request' if request else 'Connect / Ride offer',bg=C['white']))
 s.icon(20,28,'back',nav='01b-find-requests' if request else '01-find-ride');s.text(56,27,'Someone needs a lift' if request else 'A ride your way',20,800,lh=28);s.role(20,82,not request,'Ride request' if request else 'Ride offer',108)
 s.text(276,90,'● LIVE UPDATES',8,750,C['green'],94,'RIGHT',lh=12);s.map(20,125,350,149)
 s.image(20,296,43,43,'ananya' if request else 'aarav',22);s.text(75,295,'Sneha Kapoor' if request else 'Aarav Sharma',15,800,w=211,lh=22);s.text(75,320,'Sample campus member · demo',10,500,C['green'],242,lh=16)
 s.route(20,369,350);s.info(20,481,'calendar','Today',162);s.info(206,481,'clock','5:40 PM' if request else '5:30 PM',164)
 s.info(20,527,'seat','1 seat requested' if request else '3 seats available',175);s.info(206,527,'leaf','₹40 / seat',164)
 if request:s.field(20,572,350,'Connect using your matching offer','5:30 PM · 3 seats · Hyundai i20')
 else:s.field(20,572,350,'Look for','Hyundai i20 · White','car')
 s.rect(20,650,350,63,C['background'],12);s.text(34,665,'Meet by the security booth.\nConfirm the exact meeting spot in chat.',10,500,C['muted'],320,lh=17)
 s.button(20,746,350,'Offer a lift' if request else 'Connect & reserve 1 seat','07b-driver-confirmation' if request else '07-confirmation');s.text(20,808,'No payment now. Coordinate directly in chat.',9,500,C['muted'],350,'CENTER',lh=14)
# Confirmation (both roles)
for driver in (False,True):
 sid='07b-driver-confirmation' if driver else '07-confirmation';s=add(Scene(sid,'Match confirmation / '+('Driver' if driver else 'Rider'),bg=C['white']));s.header()
 s.rect(154,117,82,82,C['sage'],41);s.icon(173,137,'check',C['green'],42);s.text(20,232,'YOU’RE CONNECTED',9,800,C['green'],350,'CENTER',lh=14)
 s.text(20,263,'Good company,\nconfirmed.',33,800,w=350,align='CENTER',lh=37);s.text(20,364,'1 seat is reserved. Availability has\nupdated across the app.',12,500,C['muted'],350,'CENTER',lh=19)
 s.rect(20,430,350,174,C['background'],19,C['line']);s.route(40,450,310);s.info(40,556,'calendar','Today',94);s.info(145,556,'clock','5:30 PM',117);s.info(257,556,'seat','1 reserved',110)
 s.image(22,631,35,35,'ananya' if driver else 'aarav',18);s.text(70,629,'Sneha Kapoor' if driver else 'Aarav Sharma',13,750,w=192,lh=19);s.text(70,651,'Your rider' if driver else 'Your driver',10,500,C['muted'],192,lh=16);s.role(284,635,not driver,w=85)
 s.button(20,700,350,'Say hello in chat','09-chat');s.text(20,777,'View my matches →',12,750,C['green'],350,'CENTER',nav='08-my-matches',lh=18)
# Matches / coordination
s=add(Scene('08-my-matches','My matches / Both ride roles'));s.header();s.text(20,95,'YOUR CAMPUS CONNECTIONS',9,800,C['green'],lh=14);s.text(20,120,'Your rides.\nYour people.',30,800,lh=35)
for i,(value,label,icon) in enumerate([('2','Upcoming rides','car'),('1','Seats shared','seat'),('1','Your posts','plus')]):
 x=20+i*121;s.rect(x,219,108,109,C['ink'] if i==0 else C['white'],16,C['line']);s.icon(x+15,233,icon,'#b6d6a9' if i==0 else C['green'],17);s.text(x+15,264,value,23,800,C['white'] if i==0 else C['ink'],78,lh=29);s.text(x+15,303,label,8,500,'#b6d6a9' if i==0 else C['muted'],87,lh=12)
s.chip(20,350,'Upcoming · 2',True,'08-my-matches',119);s.chip(147,350,'My posts · 1',False,'08-my-matches',115);s.chip(270,350,'Past',False,'08-my-matches',100)
for i,driver in enumerate([False,True]):
 y=409+i*250;s.rect(20,y,350,228,C['white'],18,C['line']);s.image(37,y+17,37,37,'ananya' if driver else 'aarav',19)
 s.text(86,y+17,'Priya Nair' if driver else 'Aarav Sharma',13,800,w=174,lh=19);s.text(86,y+39,'Your campus travel partner',9,500,C['muted'],188,lh=14);s.role(244,y+69,driver,'Driving' if driver else 'Riding',107)
 s.route(37,y+72,308);s.info(37,y+171,'calendar','Today',84);s.info(125,y+171,'clock','6:00 PM' if driver else '5:30 PM',100);s.info(241,y+171,'seat','1 reserved',110)
 s.text(37,y+205,'● Connected',9,700,C['green'],154,lh=14);s.button(257,y+194,97,'Chat','09-chat',h=31)
s.nav('matches')
s=add(Scene('09-chat','Match chat / Private coordination',bg=C['white']));s.icon(20,27,'back',nav='08-my-matches');s.image(56,21,40,40,'aarav',20);s.text(108,22,'Aarav Sharma',18,800,w=220,lh=25);s.role(108,52,True,w=74);s.text(196,58,'Today · 5:30 PM',9,500,C['muted'],160,lh=14)
s.rect(20,110,350,60,C['sage'],12);s.text(34,124,'Local demo chat · saved on this device.\nNo other person is online.',10,500,C['green'],323,lh=17)
s.text(20,216,'TODAY',8,700,C['muted'],350,'CENTER',lh=13)
s.rect(95,263,275,75,C['ink'],17);s.text(110,278,'I’m at the pickup point.\nSee you at the North Gate!',12,500,C['white'],241,lh=19);s.text(110,316,'5:18 PM',8,500,'#b6d6a9',241,'RIGHT',lh=12)
s.text(20,573,'A quick hello makes a smooth pickup.',11,650,C['muted'],350,'CENTER',lh=17)
s.button(20,627,350,'I’m at the pickup point','09-chat',outline=True,h=36);s.button(20,675,350,'Running 5 min late','09-chat',outline=True,h=36)
s.rect(20,766,290,53,C['background'],13,C['line']);s.text(34,783,'Say hello. Confirm your pickup.',11,500,C['muted'],266,lh=17);s.rect(324,766,46,46,C['ink'],23);s.icon(337,779,'send',C['white'],20)
# Desktop find layout, as implemented in Flutter
s=add(Scene('10-desktop-find','Desktop / Find a ride',1440,1050));s.rect(0,0,238,1050,C['white'],0);s.rect(237,0,1,1050,C['line'],0);s.svg(22,28,38,38,logo);s.text(70,36,'RideTogether',20,800,w=145,lh=27);s.text(70,77,'YOUR CAMPUS, CONNECTED.',7,750,C['muted'],145,lh=11)
s.text(36,130,'YOUR JOURNEY',10,800,C['muted'],178,lh=15)
for i,(label,icon,nav) in enumerate([('Find a ride','search','01-find-ride'),('Post a ride','plus','02-post-route'),('My matches','people','08-my-matches')]):
 y=158+i*60
 if i==0:s.rect(22,y,193,52,C['ink'],12,nav=nav)
 s.icon(39,y+17,icon,C['white'] if i==0 else C['muted'],18,nav);s.text(70,y+16,label,12,750,C['white'] if i==0 else C['ink'],128,nav=nav,lh=20)
s.rect(22,359,193,1,C['line'],0);s.text(36,389,'How it works',11,600,C['muted'],179,lh=17);s.rect(22,791,193,177,C['background'],15);s.icon(42,815,'leaf',C['green'],26);s.text(42,857,'Go together.\nGo better.',22,800,w=155,lh=27);s.text(42,925,'Good company is just\na shared ride away.',10,500,C['muted'],150,lh=17);s.text(22,998,'● Demo · saved on this device',9,500,C['muted'],200,lh=14)
s.rect(238,0,1202,78,C['white'],0);s.rect(238,77,1202,1,C['line'],0);s.icon(285,29,'school',size=19);s.text(319,24,'YOUR CAMPUS',8,750,C['muted'],245,lh=12);s.text(319,41,'Greenfield University',12,800,w=250,lh=18);s.rect(1138,27,94,25,C['sage'],7);s.text(1147,34,'CAMPUS DEMO',8,800,C['green'],78,lh=12);s.icon(1259,30,'bell',size=19);s.image(1295,21,36,36,'rohan',18);s.text(1342,33,'Ishaan',12,750,w=75,lh=18)
s.text(274,113,'THE CAMPUS COMMUTE, REIMAGINED',10,800,C['green'],535,lh=15);s.text(274,146,'Your campus.\nYour next ride.',50,800,w=526,lh=56);s.text(274,271,'Skip the solo commute. Share a ride with\npeople heading your way.',13,500,C['muted'],500,lh=23)
for i,key in enumerate(['aarav','ananya','rohan']):s.image(274+i*21,330,31,31,key,16)
s.text(358,340,'Your people. Your way.',10,700,w=388,lh=15);s.image(827,112,577,244,'hero',21);s.rect(842,310,231,31,C['white'],9);s.icon(855,318,'leaf',C['green'],15);s.text(877,319,'Better when we go together.',10,750,w=190,lh=15)
s.rect(274,386,1130,91,C['white'],19,C['line']);s.text(295,409,'PICKUP POINT',9,800,C['muted'],287,lh=14);s.text(317,436,'North Gate',12,750,w=280,lh=18);s.icon(296,436,'pin',size=15);s.icon(616,422,'swap',size=19);s.text(659,409,'WHERE TO?',9,800,C['muted'],295,lh=14);s.text(682,436,'Riverside Metro',12,750,w=273,lh=18);s.rect(978,409,1,45,C['line'],0);s.text(1001,410,'DEPARTURE',9,800,C['muted'],203,lh=14);s.info(1001,437,'calendar','Today',214);s.button(1254,412,130,'Find rides','10-desktop-find',h=40)
s.text(274,512,'Rides heading your way',22,750,w=795,lh=28);s.text(1278,519,'● Live updates',10,700,C['green'],126,'RIGHT',lh=15)
s.chip(274,550,'Ride offers',True,'10-desktop-find',117);s.chip(399,550,'Ride requests',False,'01b-find-requests',134);s.chip(541,550,'Saved',False,'10-desktop-find',88);s.chip(637,550,'Filters',False,'10-desktop-find',89);s.text(276,610,'3 compatible rides · Today',11,500,C['muted'],600,lh=17)
for i,(name,key,car,cost,time,seats) in enumerate([('Aarav Sharma','aarav','Hyundai i20 · White','₹40','5:30 PM','3 seats left'),('Ananya Rao','ananya','Tata Nexon EV · Silver','₹30','5:45 PM','2 seats left')]):
 y=637+i*236;s.rect(274,y,813,221 if i==0 else 206,C['white'],20,C['line']);s.image(295,y+20,42,42,key,21);s.text(348,y+22,name,14,800,w=202,lh=20);s.text(348,y+49,car,11,500,C['muted'],447,lh=16);s.role(458,y+21,True,w=74);s.text(963,y+22,cost,20,800,w=64,align='RIGHT',lh=26);s.icon(1041,y+30,'bookmark',C['muted'],17);s.route(294,y+87,774,False);s.rect(294,y+120,773,1,C['line'],0);s.info(294,y+151,'calendar','Today',84);s.info(383,y+151,'clock',time,92);s.info(480,y+151,'seat',seats,220);s.button(936,y+135,131,'View ride','06-ride-details',h=40)
 if i==0:s.text(296,y+186,'ϟ Earliest on your route',10,650,C['green'],730,lh=15)
s.rect(1110,607,294,423,C['white'],20,C['line']);s.text(1128,630,'Your route',14,800,w=258,lh=20);s.map(1128,661,258,224);s.text(1128,901,'Illustrative campus map · not navigation',9,500,C['muted'],258,lh=14);s.rect(1128,929,258,1,C['line'],0);s.icon(1128,950,'pin',C['green'],18);s.text(1155,950,'Pickup made simple',12,800,w=231,lh=18);s.text(1128,978,'Meet at North Gate. Confirm the exact\nspot in chat before you leave.',11,500,C['muted'],258,lh=18)
# Design system / component vocabulary
s=add(Scene('11-design-system','Design system / Tokens & components',1200,940,bg=C['white']));s.svg(40,40,40,40,logo);s.text(94,41,'RideTogether / Design system',27,800,w=1010,lh=37);s.text(40,103,'Material 3 · warm white · ink-black · campus green · guided progress',14,500,C['muted'],1120,lh=22)
s.text(40,159,'01  Colour & role',11,800,C['green'],1120,lh=17)
for i,(name,col) in enumerate(C.items()):
 if i>8:break
 x=40+i*126;s.rect(x,194,108,63,col,12,C['line']);s.text(x,268,name,11,750,w=108,lh=17);s.text(x,289,col.upper(),9,500,C['muted'],108,lh=14)
s.role(40,339,True,'Driver / offer',128);s.role(184,339,False,'Rider / request',138);s.text(348,343,'Role is always text + icon + colour, never colour alone.',12,600,C['muted'],795,lh=18)
s.text(40,397,'02  Type / Manrope',11,800,C['green'],500,lh=17);s.text(40,433,'Go together. Go better.',43,800,w=1090,lh=52);s.text(40,502,'Heading / 26 · ExtraBold',26,800,w=1080,lh=34);s.text(40,551,'Card title / 16 · Bold',16,750,w=1080,lh=23);s.text(40,588,'Body / 13 · Medium · clear, calm and purposeful.',13,500,C['muted'],1080,lh=21)
s.text(40,646,'03  Components',11,800,C['green'],1080,lh=17);s.button(40,683,270,'Connect & reserve 1 seat','07-confirmation');s.button(329,683,215,'View ride','06-ride-details',outline=True);s.chip(567,689,'Ride offers',True,'01-find-ride',126);s.field(717,678,429,'Pickup point','North Gate','pin')
s.text(40,783,'04  Layout & motion',11,800,C['green'],1080,lh=17);s.text(40,820,'Spacing 4 / 8 / 12 / 16 / 20 / 24 / 32 · Cards 20 radius · Buttons 12 radius',13,600,w=1080,lh=21);s.text(40,854,'Mobile bottom navigation < 1024 px · Desktop sidebar ≥ 1024 px · 200 ms dissolve',12,500,C['muted'],1080,lh=20);s.text(40,899,'Design prototype only. The Flutter app is the working, stateful implementation.',10,500,C['muted'],1080,lh=16)

def svg_for(scene,embed_font=True):
 out=[f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{scene.w}" height="{scene.h}" viewBox="0 0 {scene.w} {scene.h}">']
 if embed_font:out.append(f'<style>@font-face{{font-family:Manrope;src:url(data:font/ttf;base64,{font});font-weight:200 800}}text{{font-family:Manrope,Arial,sans-serif}}</style>')
 for i,n in enumerate(scene.nodes):
  nav=f' data-to="{n.get("nav")}" style="cursor:pointer"' if n.get('nav') else ''
  name=html.escape(n.get('name',''))
  clipattr=''
  if n.get('clipRadius'):
   clipname=f'{scene.id}-svg-clip-{i}';out.append(f'<defs><clipPath id="{clipname}"><rect x="{n["x"]}" y="{n["y"]}" width="{n["w"]}" height="{n["h"]}" rx="{n["clipRadius"]}"/></clipPath></defs>');clipattr=f' clip-path="url(#{clipname})"'
  out.append(f'<g id="layer-{i}" aria-label="{name}"{nav}{clipattr}>')
  x,y,w,h=n['x'],n['y'],n.get('w'),n.get('h');kind=n['type']
  if kind=='rect':
   stroke=f' stroke="{n["stroke"]}" stroke-width="1"' if n.get('stroke') else ''
   out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{n.get("r",0)}" fill="{n["fill"]}" fill-opacity="{n.get("opacity",1)}"{stroke}/>')
  elif kind=='text':
   anchor={'LEFT':'start','CENTER':'middle','RIGHT':'end'}[n['align']];tx=x if anchor=='start' else x+w/2 if anchor=='middle' else x+w
   letter=' letter-spacing="-.6"' if n['size']>=26 else ''
   for j,line in enumerate(n['text'].split('\n')):out.append(f'<text x="{tx}" y="{y+n["size"]+j*n["lh"]}" font-size="{n["size"]}" font-weight="{min(n["weight"],800)}" fill="{n["fill"]}" text-anchor="{anchor}"{letter}>{html.escape(line)}</text>')
  elif kind=='image':
   clip=f'{scene.id}-clip-{i}';out.append(f'<defs><clipPath id="{clip}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{n.get("r",0)}"/></clipPath></defs>')
   out.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{clip})" xlink:href="data:image/jpeg;base64,{assets[n["asset"]]}"/>')
  elif kind=='svg':
   value=n['svg']
   def root_attrs(m):
    attrs=re.sub(r'\s(width|height|preserveAspectRatio)="[^"]*"','',m.group(1))
    return f'<svg{attrs} x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="none">'
   out.append(re.sub(r'<svg\b([^>]*)>',root_attrs,value,count=1))

  out.append('</g>')
 out.append('</svg>');return ''.join(out)
for s in scenes:(D/'screens'/f'{s.id}.svg').write_text(svg_for(s))
payload={'name':'RideTogether','version':'1.0','colours':C,'assets':assets,'scenes':[s.to_dict() for s in scenes]}
(D/'scenes.json').write_text(json.dumps(payload,separators=(',',':')))
(D/'tokens.json').write_text(json.dumps({'colors':C,'font':{'family':'Manrope','display':50,'mobileDisplay':38,'heading':26,'title':21,'cardTitle':16,'body':13,'caption':10},'spacing':[4,8,12,16,20,24,32],'radius':{'card':20,'button':12,'badge':7},'role':{'driver':'green + car icon + label','rider':'blue + person icon + label'},'responsive':{'mobileNavigationMaxWidth':1023,'desktopNavigationMinWidth':1024},'motion':{'durationMs':200,'curve':'easeOut'}},indent=2))
# Clickable, network-free design preview (not the live Flutter app).
rendered={s.id:svg_for(s,False) for s in scenes}
options=''.join(f'<option value="{s.id}">{html.escape(s.title)}</option>' for s in scenes)
html_doc='''<!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>RideTogether / Design prototype</title><style>FONTCSS
*{box-sizing:border-box}body{margin:0;font-family:Manrope,Arial,sans-serif;background:#eef1e9;color:#18221c}header{padding:24px 30px;background:white;display:flex;gap:24px;align-items:center;border-bottom:1px solid #dfe5d9;flex-wrap:wrap}h1{font-size:20px;margin:0;font-weight:800;letter-spacing:-.5px}header p{font-size:11px;margin:6px 0 0;color:#68736b}select,button{font-family:inherit;border:1px solid #dfe5d9;background:#f7f8f5;border-radius:10px;padding:12px 14px;font-size:11px;font-weight:700}select{max-width:100%}main{padding:30px;display:grid;grid-template-columns:minmax(220px,330px) 1fr;gap:36px}.note{background:white;border-radius:20px;padding:28px;align-self:start;position:sticky;top:30px}.note h2{font-size:27px;line-height:1.25;letter-spacing:-1px;margin:14px 0}.note p,.note li{font-size:12px;line-height:1.9;color:#68736b}.note ol{padding-left:20px}.tag{font-size:9px;letter-spacing:1.8px;font-weight:800;color:#2c6b4b}#frame{display:flex;justify-content:center;align-items:flex-start;min-width:0}#screen{width:390px;max-width:100%;box-shadow:0 18px 60px #18221c1a;border-radius:21px;overflow:hidden;background:white}#screen svg{width:100%;height:auto;display:block}.links{display:flex;flex-wrap:wrap;gap:8px;margin-top:20px}footer{font-size:10px;line-height:1.8;color:#68736b;padding:24px 30px}@media(max-width:860px){main{grid-template-columns:1fr;padding:22px}.note{position:static}.note h2{font-size:24px}#screen{margin:0 auto}.links{margin-top:12px}}
</style></head><body><header><div><h1>RideTogether <span style="color:#68736b;font-weight:500">/ Design prototype</span></h1><p>Editable screens · two role flows · guided progress · Material 3</p></div><select id="picker" aria-label="Select design screen">OPTIONS</select><button id="reset">Start the journey ↗</button></header><main><aside class="note"><span class="tag">YOUR CAMPUS, CONNECTED.</span><h2>Go together.<br>Go better.</h2><p>A premium campus carpool experience, designed around a calm and clear next step.</p><ol><li>Post an offer or a request.</li><li>Find the same route and day.</li><li>Connect and reserve a seat.</li><li>Confirm pickup in match chat.</li></ol><p><strong>Click the buttons inside each screen</strong> to explore the guided design flow. Use the screen menu to jump to any artboard.</p><div class="links"><button data-to="02-post-route">Driver flow →</button><button data-to="02b-post-request">Rider flow →</button><button data-to="10-desktop-find">Desktop →</button><button data-to="11-design-system">Design system →</button></div><p style="margin-top:22px;font-size:10px">This is a static, clickable design prototype. For working forms, live state, reservations and persistence, use the Flutter app. Import the included local plugin into Figma to generate native editable layers and link the prototype.</p></aside><section id="frame"><div id="screen"></div></section></main><footer>No external scripts, fonts or images. Sample campus and sample students. A Figma-ready design pack — not a fabricated .fig file.</footer><script>const SCREENS=SCREENJSON;const picker=document.getElementById('picker'),screen=document.getElementById('screen');function show(id,scroll=true){if(!SCREENS[id])return;picker.value=id;screen.innerHTML=SCREENS[id];screen.style.width=id.startsWith('10-')?'1440px':id.startsWith('11-')?'1200px':'390px';if(scroll)document.getElementById('frame').scrollIntoView({block:'start',behavior:'smooth'})}picker.addEventListener('change',()=>show(picker.value));document.addEventListener('click',e=>{const t=e.target.closest('[data-to]');if(t)show(t.getAttribute('data-to'))});document.getElementById('reset').onclick=()=>show('00-welcome');show('01-find-ride',false);</script></body></html>'''
html_doc=html_doc.replace('FONTCSS',f'@font-face{{font-family:Manrope;src:url(data:font/ttf;base64,{font});font-weight:200 800}}').replace('OPTIONS',options).replace('SCREENJSON',json.dumps(rendered,separators=(',',':')))
(D/'prototype.html').write_text(html_doc)
# Flow map is an independently editable vector diagram.
f=Scene('flow','Post-to-match journey',1540,580,bg=C['white']);f.text(40,32,'RideTogether / Post-to-match flow',32,800,w=1455,lh=42);f.text(40,88,'Exact route + same date + optional ±60 minutes + enough seats → a justified connection.',14,500,C['muted'],1455,lh=22)
for i,(title,body,color) in enumerate([('Campus sign-in','Demo entry or verified\nFirebase email',C['background']),('Post a ride','Offer spare seats or\nrequest a lift',C['sage']),('Find a match','Directional route,\ndate and availability',C['background']),('Review & connect','Transaction reserves\nseats atomically',C['sage']),('Confirmation','Role, route, date,\ntime, reserved seats',C['background']),('My matches & chat','Coordinate pickup.\nCancel → restore seats.',C['sage'])]):
 x=40+i*246;f.rect(x,196,216,162,color,17,C['line']);f.text(x+18,215,f'0{i+1}',11,800,C['green'],178,lh=17);f.text(x+18,252,title,16,800,w=180,lh=23);f.text(x+18,298,body,11,500,C['muted'],182,lh=19)
 if i<5:f.icon(x+221,263,'arrow',C['green'],20)
f.text(40,414,'DRIVER SIDE',10,800,C['green'],1455,lh=16);f.text(40,446,'Own compatible offer → fulfil a rider request → reserve all requested seats → private driver/rider match.',14,600,w=1455,lh=22)
f.text(40,494,'RIDER SIDE',10,800,C['blue'],1455,lh=16);f.text(40,526,'Join an offer directly, or connect your own request → seats decrease live → view connection → confirm pickup in chat.',14,600,w=1455,lh=22)
(D/'00-flow.svg').write_text(svg_for(f));payload['scenes'].append(f.to_dict());(D/'scenes.json').write_text(json.dumps(payload,separators=(',',':')))
# Local plugin UI includes everything inline; no network permission needed.
ui='''<!doctype html><html><head><meta charset="UTF-8"><style>body{margin:0;padding:30px;font-family:Inter,Arial,sans-serif;color:#18221c;background:#f7f8f5}h1{font-size:24px;letter-spacing:-.8px;margin:16px 0}p,li{font-size:12px;color:#68736b;line-height:1.9}small{font-size:9px;letter-spacing:1.8px;color:#2c6b4b;font-weight:800}ul{padding-left:19px}button{width:100%;margin-top:20px;padding:17px;border:0;border-radius:12px;background:#18221c;color:white;font-weight:700;cursor:pointer}button:disabled{opacity:.5;cursor:wait}#status{margin-top:16px;font-size:11px;color:#2c6b4b;line-height:1.8}.card{padding:18px;border-radius:14px;background:white;border:1px solid #e7ebe4;margin-top:20px}</style></head><body><small>YOUR CAMPUS, CONNECTED.</small><h1>Bring RideTogether<br>into Figma.</h1><p>Create native, editable frames for the campus carpool app — without an API key or external downloads.</p><div class="card"><ul><li>Both driver and rider posting flows</li><li>Find ride, confirmation, matches and chat</li><li>Desktop layout and component tokens</li><li>Prototype links on navigation and buttons</li><li>Native text, shapes and embedded imagery</li></ul></div><button id="import">Create the design pack →</button><div id="status">Uses Manrope when available, with Inter as a safe fallback.</div><script>const payload=PAYLOAD;document.getElementById('import').onclick=()=>{document.getElementById('import').disabled=true;document.getElementById('status').textContent='Creating editable layers. One moment…';parent.postMessage({pluginMessage:{type:'import',payload}},'*')};onmessage=e=>{if(e.data.pluginMessage){const m=e.data.pluginMessage;document.getElementById('status').textContent=m.message;document.getElementById('import').disabled=false}}</script></body></html>'''
(D/'figma-plugin'/'ui.html').write_text(ui.replace('PAYLOAD',json.dumps(payload,separators=(',',':'))))
print(f'Created {len(scenes)} screen artboards + editable flow map + native Figma import data.')
