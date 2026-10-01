/* Local development plugin; no account token or network request.
 * Turns scenes.json into native editable Figma text, vector shapes, images and
 * frames, then links the guided driver/rider journey using prototype reactions.
 */
figma.showUI(__html__, { width: 460, height: 580, themeColors: false });
let importing = false;
function rgb(hex) {
  return {r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255};
}
const paint = (hex, opacity=1) => [{type:'SOLID',color:rgb(hex),opacity}];
function svgAtSize(svg, width, height) {
  return svg.replace(/<svg\b([^>]*)>/, (_, attrs) =>
    '<svg'+attrs.replace(/\s(width|height|preserveAspectRatio)="[^"]*"/g,'')+
    ` width="${width}" height="${height}" preserveAspectRatio="none">`);
}
figma.ui.onmessage = async message => {
  if (message.type !== 'import' || importing) return;
  importing = true;
  const created = [], styles = [];
  try {
    const data = message.payload;
    const available = await figma.listAvailableFontsAsync();
    const family = ['Manrope','Inter','Arial'].find(f => available.some(n=>n.fontName.family===f)) || available[0].fontName.family;
    const familyFonts = available.filter(n=>n.fontName.family===family).map(n=>n.fontName);
    const loaded = new Map();
    async function fontFor(weight) {
      const desired = weight>=800 ? ['ExtraBold','Extra Bold','Bold','Black','Regular']
        : weight>=700 ? ['Bold','SemiBold','Semi Bold','Regular']
        : weight>=600 ? ['SemiBold','Semi Bold','Medium','Regular'] : ['Medium','Regular'];
      const found = desired.map(s=>familyFonts.find(n=>n.style===s)).find(Boolean) || familyFonts[0];
      const key = found.family+' / '+found.style;
      if (!loaded.has(key)) loaded.set(key,figma.loadFontAsync(found));
      await loaded.get(key); return found;
    }
    const hashes = {};
    for (const [key,encoded] of Object.entries(data.assets)) hashes[key] = figma.createImage(figma.base64Decode(encoded)).hash;
    for (const [key,color] of Object.entries(data.colours)) {
      const s=figma.createPaintStyle();s.name='RideTogether / '+key;s.paints=paint(color);styles.push(s);
    }
    const frames = {}, links = [];
    let mobileIndex=0;
    const mobileRows=Math.ceil(data.scenes.filter(s=>s.width===390).length/4);
    for (const scene of data.scenes) {
      const frame=figma.createFrame();created.push(frame);frame.name=scene.id+' / '+scene.title;
      frame.resize(scene.width,scene.height);frame.fills=paint('#ffffff');frame.clipsContent=true;
      if (scene.width===390) {frame.x=(mobileIndex%4)*450;frame.y=Math.floor(mobileIndex/4)*940;mobileIndex++;}
      else if (scene.id==='10-desktop-find') {frame.x=0;frame.y=mobileRows*940;}
      else if (scene.id==='11-design-system') {frame.x=1510;frame.y=mobileRows*940;}
      else {frame.x=0;frame.y=mobileRows*940+1190;}
      frame.overflowDirection='VERTICAL';
      frames[scene.id]=frame;
    }
    let count=0;
    for (const scene of data.scenes) {
      const frame=frames[scene.id];
      for (const n of scene.nodes) {
        let layer;
        if (n.type==='text') {
          layer=figma.createText();layer.fontName=await fontFor(n.weight);layer.fontSize=n.size;
          layer.characters=n.text;layer.fills=paint(n.fill);layer.lineHeight={unit:'PIXELS',value:n.lh};
          layer.textAlignHorizontal=n.align;layer.resize(n.w,Math.max(n.size*1.5,1));layer.textAutoResize='HEIGHT';
          if (n.size>=26) layer.letterSpacing={unit:'PIXELS',value:-0.6};
        } else if (n.type==='rect') {
          layer=figma.createRectangle();layer.resize(n.w,n.h);layer.cornerRadius=n.r||0;
          layer.fills=paint(n.fill,n.opacity===undefined?1:n.opacity);
          if (n.stroke) {layer.strokes=paint(n.stroke);layer.strokeWeight=1;}
        } else if (n.type==='image') {
          layer=figma.createRectangle();layer.resize(n.w,n.h);layer.cornerRadius=n.r||0;
          layer.fills=[{type:'IMAGE',imageHash:hashes[n.asset],scaleMode:'FILL'}];
        } else if (n.type==='svg') {
          layer=figma.createNodeFromSvg(svgAtSize(n.svg,n.w,n.h));
          if (n.clipRadius) {layer.cornerRadius=n.clipRadius;layer.clipsContent=true;}
        } else continue;
        frame.appendChild(layer);layer.x=n.x;layer.y=n.y;layer.name=n.name||n.type;
        if (n.nav && frames[n.nav] && typeof layer.setReactionsAsync==='function') links.push({layer,target:frames[n.nav]});
        count++;
      }
    }
    for (const {layer,target} of links) await layer.setReactionsAsync([{
      trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:target.id,navigation:'NAVIGATE',
        transition:{type:'DISSOLVE',duration:0.2,easing:{type:'EASE_OUT'}},resetScrollPosition:true}]
    }]);
    figma.currentPage.selection=[frames['01-find-ride']];
    figma.viewport.scrollAndZoomIntoView([frames['01-find-ride']]);
    figma.commitUndo();
    const text=`Created ${data.scenes.length} frames, ${count} editable layers and ${links.length} prototype links. Font: ${family}. Select Welcome or Find a ride and press Present to explore.`;
    figma.ui.postMessage({message:text});figma.notify('RideTogether designs are ready.');
  } catch (error) {
    for (const node of created) if (!node.removed) node.remove();
    for (const style of styles) if (!style.removed) style.remove();
    figma.ui.postMessage({message:'Import failed: '+(error.message||String(error))+'. See design/README.md for setup.'});
    console.error(error);
  } finally { importing=false; }
};
