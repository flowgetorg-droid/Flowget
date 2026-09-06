
const SUPABASE_URL="https://qsziiimilzpkjibezfqv.supabase.co";
const SUPABASE_ANON_KEY="sb_publishable_yyNxPCgEbnx_PYshdUjupA_tB78huDc";
const sb=supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY);
let orders=[],products=[];
const statuses=["pending","confirmed","processing","shipped","delivered","cancelled"];
const visitorEventLabels={visit:"Website Visit",page_view:"Page View",product_view:"Product Viewed",add_to_cart:"Added to Cart",remove_from_cart:"Removed from Cart",checkout_visit:"Checkout Page Visit",checkout_started:"Checkout Started",order_completed:"Order Completed"};
const money=n=>"৳"+Number(n||0).toLocaleString("bn-BD");
const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const $=id=>document.getElementById(id);

async function login(){
  $("loginErr").classList.add("hidden");
  const {data,error}=await sb.auth.signInWithPassword({email:$("email").value.trim(),password:$("password").value});
  if(error){$("loginErr").textContent=error.message;$("loginErr").classList.remove("hidden");return}
  showApp(data.user);
}
async function logout(){await sb.auth.signOut();location.reload()}
async function showApp(user){$("login").style.display="none";$("app").style.display="block";$("who").textContent=user?.email||"Admin";await refreshAll()}
async function refreshAll(){await Promise.all([loadOrders(),loadProducts(),loadReviews(),loadPaymentSettings()]);loadDashboard()}
async function loadOrders(){
 const {data,error}=await sb.from("orders").select("*").order("created_at",{ascending:false});
 if(error){$("orders").innerHTML=`<div class="order"><b>Order load failed</b><p class="muted">${esc(error.message)}</p></div>`;return}
 orders=data||[];updateStats();renderOrders();
}
function updateStats(){for(const s of ["total","pending","processing","delivered"])$(s).textContent=s==="total"?orders.length:orders.filter(o=>o.status===s).length}
function renderOrders(){
 const q=$("search").value.toLowerCase().trim(),st=$("statusFilter").value;
 const list=orders.filter(o=>{const h=[o.order_id,o.customer_name,o.customer_phone,o.district,o.upazila,o.full_address].join(" ").toLowerCase();return(!q||h.includes(q))&&(!st||o.status===st)});
 $("orders").innerHTML=list.length?list.map(card).join(""):'<div class="order"><b>কোনো order পাওয়া যায়নি।</b></div>';
}
function card(o){return `<div class="order"><div class="orderhead"><div><div class="oid">${esc(o.order_id)}</div><div class="muted">${new Date(o.created_at).toLocaleString("en-GB")}</div></div><span class="badge">${esc(o.status)}</span><div class="actions"><select onchange="setStatus('${o.id}',this.value)"><option value="">Status</option>${statuses.map(s=>`<option value="${s}">${s}</option>`).join("")}</select><button class="btn secondary" onclick="detail('${o.id}')">Details</button><button class="btn green" onclick="waOrder('${o.id}')">WhatsApp</button></div></div><div class="ordergrid"><div class="mini"><b>${esc(o.customer_name)}</b><br>📞 ${esc(o.customer_phone)}<br>${esc(o.district)}, ${esc(o.upazila)}<br>${esc(o.full_address)}</div><div class="mini">Subtotal<br><span class="money">${money(o.subtotal)}</span><br>Delivery: ${money(o.delivery_charge)}</div><div class="mini">Total<br><span class="money">${money(o.total_amount)}</span><br>${esc(o.payment_method)}${o.payment_amount?`<div class="paymentInfo">Paid: ${money(o.payment_amount)}<br>From: ${esc(o.payment_number||"-")}<br>TXID: ${esc(o.payment_transaction_id||"-")}<br>Time: ${o.payment_time?new Date(o.payment_time).toLocaleString("bn-BD"):"-"}</div>`:""}</div></div></div>`}
async function setStatus(id,status){if(!status)return;const {error}=await sb.from("orders").update({status}).eq("id",id);if(error)return alert(error.message);await loadOrders()}
function detail(id){const o=orders.find(x=>x.id===id);if(!o)return;let items=Array.isArray(o.order_items)?o.order_items:[];$("detail").innerHTML=`<p><b>Order ID:</b> ${esc(o.order_id)}</p><p><b>Customer:</b> ${esc(o.customer_name)}<br><b>Phone:</b> ${esc(o.customer_phone)}<br><b>Email:</b> ${esc(o.customer_email||"-")}</p><p><b>Address:</b> ${esc(o.division)}, ${esc(o.district)}, ${esc(o.upazila)}, ${esc(o.union_or_area||"")}<br>${esc(o.full_address)}</p><p><b>Note:</b> ${esc(o.delivery_note||"-")}<br><b>Payment:</b> ${esc(o.payment_method)}<br><b>Payment Number:</b> ${esc(o.payment_number||"-")}<br><b>Transaction ID:</b> ${esc(o.payment_transaction_id||"-")}<br><b>Payment Amount:</b> ${o.payment_amount?money(o.payment_amount):"-"}<br><b>Payment Time:</b> ${o.payment_time?new Date(o.payment_time).toLocaleString("bn-BD"):"-"}<br><b>Status:</b> ${esc(o.status)}</p><h3>Products</h3><div class="items">${items.map(x=>`<div class="item"><span>${esc(x.name)} × ${esc(x.quantity)}</span><b>${money(Number(x.price)*Number(x.quantity))}</b></div>`).join("")}</div><hr><p>Subtotal: ${money(o.subtotal)}<br>Delivery: ${money(o.delivery_charge)}<br><b>Total: ${money(o.total_amount)}</b></p>`;$("modal").classList.add("open")}
function closeModal(){$("modal").classList.remove("open")}
function waOrder(id){const o=orders.find(x=>x.id===id);if(!o)return;const msg=`আসসালামু আলাইকুম, FlowGet থেকে আপনার অর্ডার ${o.order_id} এর আপডেট: Status: ${o.status}; Total: ${money(o.total_amount)}।`;window.open("https://wa.me/88"+String(o.customer_phone).replace(/^0/,"")+"?text="+encodeURIComponent(msg),"_blank")}
let orderMap=null,orderMapLayer=null;const districtCoords={"ঢাকা":[23.8103,90.4125],"চট্টগ্রাম":[22.3569,91.7832],"কুমিল্লা":[23.4607,91.1809],"নোয়াখালী":[22.8696,91.0995],"ফেনী":[23.0159,91.3976],"লক্ষ্মীপুর":[22.9447,90.8412],"চাঁদপুর":[23.2333,90.6712],"ব্রাহ্মণবাড়িয়া":[23.9571,91.1119],"সিলেট":[24.8949,91.8687],"রাজশাহী":[24.3745,88.6042],"খুলনা":[22.8456,89.5403],"বরিশাল":[22.7010,90.3535],"রংপুর":[25.7439,89.2752],"ময়মনসিংহ":[24.7471,90.4203],"গাজীপুর":[24.0023,90.4264],"নারায়ণগঞ্জ":[23.6238,90.5000],"কক্সবাজার":[21.4272,92.0058],"যশোর":[23.1664,89.2089],"বগুড়া":[24.8465,89.3770],"দিনাজপুর":[25.6279,88.6332]};
function renderOrderMap(){const el=$("orderMap");if(!el)return;if(!orderMap){orderMap=L.map(el).setView([23.685,90.3563],7);L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:18,attribution:"© OpenStreetMap"}).addTo(orderMap);orderMapLayer=L.layerGroup().addTo(orderMap)}if(orderMapLayer)orderMapLayer.clearLayers();const counts={};orders.forEach(o=>{if(o.status!=="cancelled")counts[o.district]=(counts[o.district]||0)+1});Object.entries(counts).forEach(([d,n])=>{const c=districtCoords[d]||districtCoords["ঢাকা"];L.marker(c,{title:d}).addTo(orderMapLayer).bindPopup(`<b>${esc(d)}</b><br>${n}টি order`)});setTimeout(()=>orderMap.invalidateSize(),100)}
function showTab(t){
 const names=["dashboard","orders","products","reviews","marketing","visitors"];
 names.forEach(x=>{const el=$(x+"Tab"),tab=$("tab"+x.charAt(0).toUpperCase()+x.slice(1));if(el)el.classList.toggle("hidden",x!==t);if(tab)tab.classList.toggle("active",x===t)});
 if(t==="dashboard"){loadDashboard();setTimeout(renderOrderMap,100)}
 if(t==="reviews")loadReviews();
 if(t==="orders")renderOrders();
 if(t==="products")renderProducts();
 if(t==="marketing"){loadCoupons();loadSpinSettings();loadPaymentSettings();loadBanners()}
 if(t==="visitors")loadVisitors();
}

async function loadVisitors(){
 const list=$("visitorList"),detail=$("visitorDetail");if(!list)return;
 const [{data:visitors,error:vErr},{count:total},{count:productViews},{count:adds},{count:checkouts},{count:completed}] = await Promise.all([
   sb.from("anonymous_visitors").select("visitor_id,first_visit,last_active,page_views").order("last_active",{ascending:false}).limit(50),
   sb.from("anonymous_visitors").select("visitor_id",{count:"exact",head:true}),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","product_view"),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","add_to_cart"),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).in("event_type",["checkout_visit","checkout_started"]),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","order_completed")
 ]);
 if(vErr){list.innerHTML=`<div class="err">Visitor load failed: ${esc(vErr.message)}</div>`;return}
 $("visitorTotal").textContent=total||0;$("visitorProductViews").textContent=productViews||0;$("visitorAdds").textContent=adds||0;$("visitorCheckouts").textContent=checkouts||0;$("visitorOrders").textContent=completed||0;
 const recentCut=Date.now()-24*60*60*1000;$("visitorActive").textContent=(visitors||[]).filter(v=>new Date(v.last_active).getTime()>=recentCut).length;
 list.innerHTML=(visitors||[]).map(v=>`<div class="visitorCard"><div><b>${esc(v.visitor_id)}</b><div class="meta">First: ${new Date(v.first_visit).toLocaleString("en-GB")} • Last active: ${new Date(v.last_active).toLocaleString("en-GB")} • Page views: ${v.page_views||0}</div></div><button class="btn secondary" onclick="showVisitor('${v.visitor_id}')">View Activity</button></div>`).join("")||'<p class="muted">কোনো visitor activity নেই।</p>';
}
async function showVisitor(visitorId){
 const box=$("visitorDetail");if(!box)return;box.classList.remove("hidden");box.innerHTML="Loading...";
 const {data,error}=await sb.from("visitor_events").select("id,event_type,created_at,product_id,order_id,products(name,sku)").eq("visitor_id",visitorId).order("created_at",{ascending:false}).limit(100);
 if(error){box.innerHTML=`<div class="err">${esc(error.message)}</div>`;return}
 box.innerHTML=`<div style="display:flex;justify-content:space-between;gap:8px"><h3>Visitor: ${esc(visitorId)}</h3><button class="btn secondary" onclick="$("visitorDetail").classList.add("hidden")">Close</button></div><div class="timeline">${(data||[]).map(e=>`<div class="event"><b>${esc(visitorEventLabels[e.event_type]||e.event_type)}</b>${e.products?.name?` — ${esc(e.products.name)}`:""}${e.order_id?` — ${esc(e.order_id)}`:""}<small>${new Date(e.created_at).toLocaleString("en-GB")}</small></div>`).join("")||'<p class="muted">কোনো activity নেই।</p>'}</div>`;
}

function getThreshold(){return Number(localStorage.getItem("flowget_low_threshold")||5)}
function saveThreshold(){const v=Math.max(0,Number($("lowThreshold").value||5));localStorage.setItem("flowget_low_threshold",v);renderInventory()}
function orderDateKey(d){const x=new Date(d);return x.toISOString().slice(0,10)}
function formatDay(key){const d=new Date(key+"T00:00:00");return d.toLocaleDateString("bn-BD",{day:"2-digit",month:"short"})}
async function loadDashboard(){
 if(!products.length)await loadProducts();
 if(!orders.length)await loadOrders();
 const revenue=orders.filter(o=>o.status!=="cancelled").reduce((a,o)=>a+Number(o.total_amount||0),0);
 const todayKey=orderDateKey(new Date());
 const today=orders.filter(o=>o.status!=="cancelled"&&orderDateKey(o.created_at)===todayKey).reduce((a,o)=>a+Number(o.total_amount||0),0);
 $("dashRevenue").textContent=money(revenue);$("dashToday").textContent=money(today);$("dashProducts").textContent=products.length;
 $("lowThreshold").value=getThreshold();
 const low=products.filter(p=>Number(p.stock||0)<=getThreshold()).length;$("dashLow").textContent=low;
 const days=[];for(let i=6;i>=0;i--){const d=new Date();d.setHours(0,0,0,0);d.setDate(d.getDate()-i);days.push(orderDateKey(d))}
 const vals=days.map(k=>orders.filter(o=>o.status!=="cancelled"&&orderDateKey(o.created_at)===k).reduce((a,o)=>a+Number(o.total_amount||0),0));
 const max=Math.max(...vals,1);$("salesBars").innerHTML=days.map((k,i)=>`<div class="barrow"><span>${formatDay(k)}</span><div class="bar"><i style="width:${Math.round(vals[i]/max*100)}%"></i></div><b>${money(vals[i])}</b></div>`).join("");
 const counts={};orders.filter(o=>o.status!=="cancelled").forEach(o=>(Array.isArray(o.order_items)?o.order_items:[]).forEach(it=>{const n=it.name||"Product";counts[n]=(counts[n]||0)+Number(it.quantity||it.qty||1)}));
 const top=Object.entries(counts).sort((a,b)=>b[1]-a[1]).slice(0,7);$("topProducts").innerHTML=top.length?top.map((x,i)=>`<div class="item"><span>${i+1}. ${esc(x[0])}</span><b>${x[1]} sold</b></div>`).join(""):'<p class="muted">এখনও sales data নেই।</p>';
 renderInventory();
 renderOrderMap();
 loadDashboardVisitorStats();
}
async function loadDashboardVisitorStats(){
 const ids=["dashVisitorsToday","dashViewsToday","dashAddsToday","dashConversion"];
 if(ids.some(id=>!$(id)))return;
 try{
  const now=new Date(),start=new Date(now);start.setHours(0,0,0,0);const end=new Date(start);end.setDate(end.getDate()+1);
  const [v,p,a,o]=await Promise.all([
   sb.from("anonymous_visitors").select("visitor_id",{count:"exact",head:true}).gte("first_visit",start.toISOString()).lt("first_visit",end.toISOString()),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","product_view").gte("created_at",start.toISOString()).lt("created_at",end.toISOString()),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","add_to_cart").gte("created_at",start.toISOString()).lt("created_at",end.toISOString()),
   sb.from("visitor_events").select("id",{count:"exact",head:true}).eq("event_type","order_completed").gte("created_at",start.toISOString()).lt("created_at",end.toISOString())
  ]);
  const visitors=v.count||0,views=p.count||0,adds=a.count||0,ordersToday=o.count||0;
  $("dashVisitorsToday").textContent=visitors;$("dashViewsToday").textContent=views;$("dashAddsToday").textContent=adds;$("dashConversion").textContent=visitors?((ordersToday/visitors)*100).toFixed(2)+"%":"0%";
 }catch(e){console.debug("dashboard visitor stats",e)}
}
function renderInventory(){
 const th=getThreshold();const list=[...products].sort((a,b)=>Number(a.stock||0)-Number(b.stock||0));
 $("inventoryBody").innerHTML=list.map(p=>{const stock=Number(p.stock||0), cls=stock===0?"out":stock<=th?"low":"";const status=stock===0?"Out of stock":stock<=th?"Low stock":"In stock";return `<tr class="${cls}"><td><b>${esc(p.name)}</b></td><td>${esc(p.sku||"—")}</td><td><input id="stk-${p.id}" class="stockInput" type="number" min="0" value="${stock}"></td><td>${th}</td><td>${status}</td><td><button class="btn secondary" onclick="quickStock('${p.id}')">Save</button></td></tr>`}).join("")||'<tr><td colspan="6">কোনো product নেই।</td></tr>';
}
async function quickStock(id){const v=Math.max(0,Number($("stk-"+id).value||0));const {error}=await sb.from("products").update({stock:v,updated_at:new Date().toISOString()}).eq("id",id);if(error)return alert(error.message);const p=products.find(x=>x.id===id);if(p)p.stock=v;renderInventory();renderProducts();}
function exportOrdersCSV(){
 const rows=[["Order ID","Customer","Phone","District","Area","Total","Status","Created At"]];orders.forEach(o=>rows.push([o.order_id,o.customer_name,o.customer_phone,o.district,o.union_or_area||"",o.total_amount,o.status,o.created_at]));
 const csv=rows.map(r=>r.map(v=>`"${String(v??"").replaceAll('"','""')}"`).join(",")).join("\n");const blob=new Blob(["\ufeff"+csv],{type:"text/csv;charset=utf-8"});const a=document.createElement("a");a.href=URL.createObjectURL(blob);a.download="flowget-orders.csv";a.click();URL.revokeObjectURL(a.href);
}

let siteSettingsAdmin={};
async function loadSiteSettings(){
 const err=$("siteSetErr"),msg=$("siteSetMsg"); if(!$("siteBrandName"))return; err?.classList.add("hidden");
 const {data,error}=await sb.from("site_settings").select("*").eq("id",1).maybeSingle();
 if(error){if(err){err.textContent="Site settings load failed: "+error.message;err.classList.remove("hidden")}return}
 siteSettingsAdmin=data||{};
 $("siteBrandName").value=data?.brand_name||"FlowGet"; $("siteTitleText").value=data?.site_title||"FlowGet"; $("siteTopbar").value=data?.topbar_text||"";
 $("siteHeroBadge").value=data?.hero_badge||"🔥 FLASH SALE"; $("siteHeroTitle").value=data?.hero_title||""; $("siteHeroSubtitle").value=data?.hero_subtitle||""; $("siteHeroButton").value=data?.hero_button||"অফার দেখুন"; if($("siteTextOverrides"))$("siteTextOverrides").value=JSON.stringify(data?.custom_texts||{},null,2);
 $("siteWhatsapp").value=data?.whatsapp_number||"01822024595"; $("siteEmail").value=data?.contact_email||"flowget.org@gmail.com"; $("siteFooterText").value=data?.footer_text||""; $("siteLogoUrl").value=data?.logo_url||"";
 if(data?.logo_url){$("siteLogoPreview").src=data.logo_url;$("siteLogoPreview").classList.remove("hidden")}
}
function previewSiteLogo(){const f=$("siteLogoFile")?.files?.[0]; if(!f)return; $("siteLogoName").textContent=`${f.name} (${Math.round(f.size/1024)} KB)`; const img=$("siteLogoPreview"); img.src=URL.createObjectURL(f); img.classList.remove("hidden");}
async function uploadSiteLogo(file){
 const ext=(file.name.split(".").pop()||"png").toLowerCase(); const path="brand/"+Date.now()+"-"+crypto.randomUUID()+"."+ext;
 const {error}=await sb.storage.from("site-assets").upload(path,file,{upsert:false,contentType:file.type||undefined}); if(error)throw error; return sb.storage.from("site-assets").getPublicUrl(path).data.publicUrl;
}
async function saveSiteSettings(){
 const err=$("siteSetErr"),msg=$("siteSetMsg"); err.classList.add("hidden");
 let customTexts={};try{customTexts=JSON.parse($("siteTextOverrides")?.value||"{}")}catch(e){err.textContent="Extra Website Text JSON invalid";err.classList.remove("hidden");return} const payload={custom_texts:customTexts,brand_name:$("siteBrandName").value.trim()||"FlowGet",site_title:$("siteTitleText").value.trim()||"FlowGet",topbar_text:$("siteTopbar").value.trim(),hero_badge:$("siteHeroBadge").value.trim(),hero_title:$("siteHeroTitle").value.trim(),hero_subtitle:$("siteHeroSubtitle").value.trim(),hero_button:$("siteHeroButton").value.trim(),whatsapp_number:$("siteWhatsapp").value.trim(),contact_email:$("siteEmail").value.trim(),footer_text:$("siteFooterText").value.trim(),logo_url:$("siteLogoUrl").value.trim()||null,updated_at:new Date().toISOString()};
 try{const f=$("siteLogoFile").files[0]; if(f)payload.logo_url=await uploadSiteLogo(f); const {error}=await sb.from("site_settings").update(payload).eq("id",1); if(error)throw error; $("siteLogoUrl").value=payload.logo_url||""; msg.textContent="✅ Site settings saved. Website reload করলে নতুন logo/text দেখা যাবে."; msg.classList.remove("hidden"); setTimeout(()=>msg.classList.add("hidden"),3500);}catch(e){err.textContent=e.message||"Save failed";err.classList.remove("hidden")}
}

async function loadPaymentSettings(){const {data,error}=await sb.from("payment_settings").select("bkash_number,nagad_number,rocket_number").eq("id",1).maybeSingle();if(error)return;$("adminBkash").value=data?.bkash_number||"";$("adminNagad").value=data?.nagad_number||"";$("adminRocket").value=data?.rocket_number||""}
async function savePaymentSettings(){const {error}=await sb.from("payment_settings").update({bkash_number:$("adminBkash").value.trim(),nagad_number:$("adminNagad").value.trim(),rocket_number:$("adminRocket").value.trim(),updated_at:new Date().toISOString()}).eq("id",1);if(error)return alert(error.message);$("paymentSetMsg").textContent="Payment numbers saved.";$("paymentSetMsg").classList.remove("hidden");setTimeout(()=>$("paymentSetMsg").classList.add("hidden"),2500)}
async function loadReviews(){const {data,error}=await sb.from("product_reviews").select("*,products(name)").order("created_at",{ascending:false});if(error){$("reviews").innerHTML=`<p>${esc(error.message)}</p>`;return} $("reviews").innerHTML=(data||[]).map(r=>`<div class="product"><div><b>${esc(r.products?.name||"Product")}</b><div class="meta">${esc(r.customer_name)} • ${"★".repeat(r.rating)}${"☆".repeat(5-r.rating)}</div><p>${esc(r.review_text)}</p><small>${r.approved?"✅ Approved":"⏳ Pending"}</small></div><div class="actions">${r.approved?`<button class="btn secondary" onclick="reviewApprove('${r.id}',false)">Hide</button>`:`<button class="btn primary" onclick="reviewApprove('${r.id}',true)">Approve</button>`}<button class="btn danger" onclick="reviewDelete('${r.id}')">Delete</button></div></div>`).join("")||"<p>কোনো review নেই।</p>"}
async function reviewApprove(id,approved){const {error}=await sb.from("product_reviews").update({approved}).eq("id",id);if(error)return alert(error.message);await loadReviews()}
async function reviewDelete(id){if(!confirm("Review delete করবেন?"))return;const {error}=await sb.from("product_reviews").delete().eq("id",id);if(error)return alert(error.message);await loadReviews()}
function clearBannerForm(){
 ["bannerId","bannerBadge","bannerTitle","bannerSubtitle","bannerButton","bannerLink","bannerImage","bannerSort"].forEach(id=>$(id).value="");
 $("bannerSort").value="1";$("bannerButton").value="অফার দেখুন";$("bannerLink").value="#shop";$("bannerActive").checked=true;$("bannerPreview").classList.add("hidden");$("bannerErr").classList.add("hidden");
}
function previewBannerUrl(){const u=$("bannerImage").value.trim();const im=$("bannerPreview");if(!u){im.classList.add("hidden");im.removeAttribute("src");return}im.src=u;im.classList.remove("hidden")}
async function loadBanners(){
 const box=$("bannerList");if(!box)return;
 const {data,error}=await sb.from("homepage_banners").select("*").order("sort_order",{ascending:true}).order("created_at",{ascending:true});
 if(error){box.innerHTML=`<div class="err">Banner table not ready. ${esc(error.message)}</div>`;return}
 box.innerHTML=(data||[]).map(b=>`<div class="bannerItem"><img src="${esc(b.image_url||"")}" onerror="this.style.display='none'" alt=""><div><b>${esc(b.title)}</b><div class="meta">${esc(b.badge||"")} • Order: ${b.sort_order} • ${b.active?"Active":"Hidden"}</div><div class="meta">${esc(b.subtitle||"")}</div></div><div class="actions"><button class="btn secondary" onclick="editBanner('${b.id}')">Edit</button><button class="btn ${b.active?'danger':'green'}" onclick="toggleBanner('${b.id}',${!b.active})">${b.active?'Hide':'Show'}</button><button class="btn danger" onclick="deleteBanner('${b.id}')">Delete</button></div></div>`).join("")||'<p class="muted">কোনো banner নেই।</p>';
}
function editBanner(id){sb.from("homepage_banners").select("*").eq("id",id).maybeSingle().then(({data,error})=>{if(error||!data)return alert(error?.message||"Banner পাওয়া যায়নি");$("bannerId").value=data.id;$("bannerBadge").value=data.badge||"";$("bannerTitle").value=data.title||"";$("bannerSubtitle").value=data.subtitle||"";$("bannerButton").value=data.button_text||"";$("bannerLink").value=data.button_link||"#shop";$("bannerImage").value=data.image_url||"";$("bannerSort").value=data.sort_order??1;$("bannerActive").checked=!!data.active;previewBannerUrl();window.scrollTo({top:0,behavior:"smooth"})})}
async function saveBanner(){
 const err=$("bannerErr");err.classList.add("hidden");const title=$("bannerTitle").value.trim();if(!title){err.textContent="Banner Title দিন।";err.classList.remove("hidden");return}
 const payload={badge:$("bannerBadge").value.trim(),title,subtitle:$("bannerSubtitle").value.trim(),button_text:$("bannerButton").value.trim(),button_link:$("bannerLink").value.trim()||"#shop",image_url:$("bannerImage").value.trim()||null,sort_order:Math.max(0,Number($("bannerSort").value||0)),active:$("bannerActive").checked,updated_at:new Date().toISOString()};
 const id=$("bannerId").value;const r=id?await sb.from("homepage_banners").update(payload).eq("id",id):await sb.from("homepage_banners").insert(payload);if(r.error){err.textContent=r.error.message;err.classList.remove("hidden");return}clearBannerForm();await loadBanners();alert("Banner saved successfully.");
}
async function toggleBanner(id,active){const {error}=await sb.from("homepage_banners").update({active,updated_at:new Date().toISOString()}).eq("id",id);if(error)return alert(error.message);loadBanners()}
async function deleteBanner(id){if(!confirm("এই banner delete করবেন?"))return;const {error}=await sb.from("homepage_banners").delete().eq("id",id);if(error)return alert(error.message);loadBanners()}

async function loadProducts(){const {data,error}=await sb.from("products").select("*").order("created_at",{ascending:false});if(error){$("products").innerHTML=`<div class="product"><b>Products load failed</b><p class="muted">${esc(error.message)}</p></div>`;return}products=data||[];renderProducts()}
function renderProducts(){const q=$("productSearch").value.toLowerCase().trim();const list=products.filter(p=>(p.name+" "+p.category+" "+(p.sku||"")).toLowerCase().includes(q));$("products").innerHTML=list.length?list.map(p=>{const imgs=Array.isArray(p.images)&&p.images.length?p.images:(p.image?[p.image]:[]);return `<div class="product"><img src="${esc(imgs[0]||"")}" onerror="this.style.opacity='.2'"><div><h3>${esc(p.name)}</h3><div class="meta">${esc(p.category)} • ${money(p.price)} • Stock: ${p.stock} • ${imgs.length} photo${p.video_url?" • 🎥 Video":""} • ${p.active?"Active":"Hidden"}${p.featured?" • ⭐ Featured":""}</div><div class="muted">${esc(p.sku||"")}</div></div><div class="actions"><button class="btn secondary" onclick="editProduct('${p.id}')">Edit</button><button class="btn danger" onclick="deleteProduct('${p.id}')">Delete</button></div></div>`}).join(""):'<div class="product"><b>কোনো product নেই।</b></div>'}
function clearProductForm(){
 ["productId","pName","pCategory","pPrice","pOld","pStock","pSku","pBadge","pImage","pDetails","pSpecs","pColors","pSizes"].forEach(id=>$(id).value="");
 $("pFeatured").checked=false;$("pActive").checked=true;$("pFile").value="";$("pVideo").value="";
 $("previews").innerHTML="";$("imageCount").textContent="কোনো ছবি নির্বাচিত হয়নি";$("videoName").textContent="কোনো ভিডিও নির্বাচিত হয়নি";
 $("formTitle").textContent="➕ নতুন Product";$("productErr").classList.add("hidden");
}
function editProduct(id){
 const p=products.find(x=>x.id===id);if(!p)return;
 $("productId").value=p.id;$("pName").value=p.name;$("pCategory").value=p.category;$("pPrice").value=p.price;
 $("pOld").value=p.old_price||"";$("pStock").value=p.stock||0;$("pSku").value=p.sku||"";$("pBadge").value=p.badge||"";
 $("pImage").value=p.image||"";$("pDetails").value=p.details||"";$("pSpecs").value=p.specifications||"";
 $("pColors").value=Array.isArray(p.colors)?p.colors.join(", "):"";$("pSizes").value=Array.isArray(p.sizes)?p.sizes.join(", "):"";
 $("pFeatured").checked=!!p.featured;$("pActive").checked=!!p.active;
 $("previews").innerHTML=(Array.isArray(p.images)&&p.images.length?p.images:(p.image?[p.image]:[])).map(u=>`<img src="${esc(u)}">`).join("");
 $("imageCount").textContent=`${Array.isArray(p.images)?p.images.length:(p.image?1:0)}টি saved ছবি`;
 $("videoName").textContent=p.video_url?"ভিডিও সংরক্ষিত আছে":"কোনো ভিডিও নেই";
 $("formTitle").textContent="✏️ Product Edit";showTab("products");scrollTo({top:0,behavior:"smooth"});
}
function previewFiles(){
 const fs=[...$("pFile").files];$("imageCount").textContent=fs.length?`${fs.length}টি ছবি নির্বাচিত`:"কোনো ছবি নির্বাচিত হয়নি";
 $("previews").innerHTML=fs.map(f=>`<img src="${URL.createObjectURL(f)}" alt="">`).join("");
}
function previewVideo(){const f=$("pVideo").files[0];$("videoName").textContent=f?`${f.name} (${Math.round(f.size/1024/1024*10)/10} MB)`:"কোনো ভিডিও নির্বাচিত হয়নি"}
async function uploadMedia(file){
 const ext=(file.name.split(".").pop()||"bin").toLowerCase();
 const path=Date.now()+"-"+crypto.randomUUID()+"."+ext;
 const {error}=await sb.storage.from("product-images").upload(path,file,{upsert:false,contentType:file.type||undefined});
 if(error)throw error;
 return sb.storage.from("product-images").getPublicUrl(path).data.publicUrl;
}
async function saveProduct(){
 const err=$("productErr");err.classList.add("hidden");
 const name=$("pName").value.trim(),category=$("pCategory").value.trim(),price=Number($("pPrice").value),old=Number($("pOld").value||0),stock=Math.max(0,Number($("pStock").value||0));
 if(!name||!category||!Number.isFinite(price)){err.textContent="Name, Category ও Price দিন।";err.classList.remove("hidden");return}
 const btn=document.querySelector('#productsTab .formbox .primary');btn.disabled=true;btn.textContent="Saving...";
 try{
  let image=$("pImage").value.trim()||null;
  let images=[];
  if($("pFile").files.length){
    for(const f of $("pFile").files) images.push(await uploadMedia(f));
    if(!image) image=images[0]||null;
  }
  const colors=$("pColors").value.split(",").map(x=>x.trim()).filter(Boolean);
  const sizes=$("pSizes").value.split(",").map(x=>x.trim()).filter(Boolean);
  let video_url=null;
  if($("pVideo").files[0]) video_url=await uploadMedia($("pVideo").files[0]);
  else {
    const existing=products.find(x=>x.id===$("productId").value); video_url=existing?.video_url||null;
  }
  const existing=products.find(x=>x.id===$("productId").value);
  if(!images.length && existing) images=Array.isArray(existing.images)&&existing.images.length?existing.images:(existing.image?[existing.image]:[]);
  const payload={name,category,price,old_price:old,discount:old>0?Math.max(0,Math.round((old-price)/old*100)):0,image,images,video_url,
    details:$("pDetails").value.trim(),specifications:$("pSpecs").value.trim(),sku:$("pSku").value.trim(),
    colors,sizes,stock,badge:$("pBadge").value.trim(),featured:$("pFeatured").checked,active:$("pActive").checked,updated_at:new Date().toISOString()};
  const id=$("productId").value;const r=id?await sb.from("products").update(payload).eq("id",id):await sb.from("products").insert(payload);
  if(r.error)throw r.error;clearProductForm();await loadProducts();
 }catch(e){err.textContent=e.message||"Save failed";err.classList.remove("hidden")}
 btn.disabled=false;btn.textContent="Save Product";
}
async function deleteProduct(id){const p=products.find(x=>x.id===id);if(!p)return;if(!confirm(`"${p.name}" delete করবেন?`))return;const {error}=await sb.from("products").delete().eq("id",id);if(error)return alert(error.message);await loadProducts()}
sb.auth.getSession().then(({data})=>{if(data.session)showApp(data.session.user)});
