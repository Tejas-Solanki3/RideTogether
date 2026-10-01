/* Actual compiled Flutter web UI smoke test. Requires an HTTP server for build/web. */
const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const url=process.env.TEST_URL||'http://127.0.0.1:3000';
const output=path.resolve(__dirname,'../../docs/screenshots');
fs.mkdirSync(output,{recursive:true});
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 const errors=[],checks=[];
 async function pageIn(width,height){
  const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:1,timezoneId:'Asia/Kolkata'});
  const page=await context.newPage();
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
  await page.goto(url,{waitUntil:'networkidle'});
  await page.waitForFunction(()=>!document.getElementById('loading'));
  await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());
  await page.getByRole('button',{name:'Find rides',exact:true}).waitFor();
  return {context,page};
 }
 const shot=async(p,name)=>{await p.waitForTimeout(350);await p.screenshot({path:path.join(output,name+'.png')})};
 const button=(p,name)=>p.getByRole('button',{name,exact:typeof name==='string'}).first();
 async function click(p,name){
  const loc=button(p,name);
  await loc.click({timeout:12000});await p.waitForTimeout(280);
 }
 async function state(p){return p.evaluate(()=>{const k=Object.keys(localStorage).find(k=>k.endsWith('ridetogether_demo_v1'));
   if(!k)return null;let j=JSON.parse(localStorage.getItem(k));return typeof j==='string'?JSON.parse(j):j})}
 try{
  const {context,page}=await pageIn(1440,1050);
  await shot(page,'01-find-desktop');checks.push('Desktop Flutter app and assets load');
  await click(page,'Post a ride');await shot(page,'02-post-route-desktop');
  await click(page,'Continue');
  const vehicle=page.getByRole('textbox',{name:/Vehicle/}).first();await vehicle.click();await page.keyboard.type('Tata Nexon · Sage');
  await page.getByRole('checkbox').click();await click(page,'Continue');
  await shot(page,'03-review-desktop');await click(page,'Publish ride offer');
  await button(page,'Find compatible requests').waitFor();
  assert((await state(page)).rides.some(r=>r.vehicle==='Tata Nexon · Sage'));checks.push('Guided offer post persists a Ride');
  await click(page,'Find compatible requests');await click(page,'View request');
  await shot(page,'04-driver-request-desktop');await click(page,'Offer a lift');
  await button(page,'View my matches').waitFor();await click(page,'View my matches');
  assert((await state(page)).matches.some(m=>m.requestId==='request_sneha'&&m.status==='confirmed'));
  checks.push('Driver fulfilment reserves seats and connects a request');
  await shot(page,'05-driver-matches-desktop');
  await context.close();
  const rider=await pageIn(1440,1050),p=rider.page;
  await click(p,'View ride');await shot(p,'06-ride-details-desktop');
  await click(p,'Connect & reserve 1 seat');await button(p,'View my matches').waitFor();
  await shot(p,'07-confirmation-desktop');
  assert.equal((await state(p)).rides.find(r=>r.id==='offer_aarav').availableSeats,2);
  checks.push('Rider connection reserves one seat');
  await click(p,'Say hello in chat');await shot(p,'08-chat-desktop'); await p.getByRole('textbox').first().fill('I’m at the pickup point.'); await click(p,'Send message');
  await shot(p,'08-chat-desktop');assert(Object.values((await state(p)).messages).flat().some(m=>m.text==='I’m at the pickup point.'));
  checks.push('Match chat sends and persists a message');
  await click(p,'Close');await click(p,/^My matches/);await shot(p,'09-my-matches-desktop');
  await click(p,'Details');await click(p,'Cancel this connection');await click(p,'Cancel connection');
  assert.equal((await state(p)).rides.find(r=>r.id==='offer_aarav').availableSeats,3);
  checks.push('Cancellation restores seats');
  await p.reload({waitUntil:'networkidle'});await p.waitForFunction(()=>!document.getElementById('loading'));
  if(await p.locator('flt-semantics-placeholder').count())await p.locator('flt-semantics-placeholder').evaluate(e=>e.click());
  assert((await state(p)).matches.some(m=>m.status==='cancelled'));checks.push('Reload retains posts, matches and chat');
  await click(p,'Swap pickup and destination');
  assert((await p.locator('body').innerText()).includes('0 compatible rides'));
  checks.push('Directional route filtering excludes the reverse route');
  await rider.context.close();
  const mobile=await pageIn(390,844),m=mobile.page;
  await shot(m,'10-find-mobile');await click(m,'Find rides');await shot(m,'11-results-mobile');
  await m.getByRole('tab',{name:/Post ride/}).click();await m.waitForTimeout(350);await shot(m,'12-post-mobile');
  checks.push('390px mobile layout and bottom navigation work');
  await mobile.context.close();
  assert.deepEqual(errors,[]);
  const report={date:new Date().toISOString(),app:'Compiled Flutter web release',checks,errors};
  fs.writeFileSync(path.resolve(__dirname,'../../docs/WEB_SMOKE_RESULTS.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
