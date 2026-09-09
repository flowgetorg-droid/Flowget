import React,{useEffect,useState}from'react';
import{supabase}from'../lib/supabase';
import{getProducts,getCategories,getSettings}from'../lib/store';
import{Upload,Image as ImageIcon,Video,Menu,X}from'lucide-react';
const TABS=['dashboard','products','categories','orders','coupons','banners','settings'];
const emptyProduct={name:'',slug:'',short_description:'',description:'',category_id:'',brand:'',sku:'',price:'',discount_price:'',stock:'0',main_image:'',video_url:'',active:true};
const emptyCategory={name:'',slug:'',description:'',icon:'✦',sort_order:0,active:true};
const emptyCoupon={code:'',coupon_type:'percentage',discount_value:'',min_order:0,max_discount:'',usage_limit:'',per_customer_limit:1,start_at:'',expires_at:'',active:true};
const emptyBanner={title:'',subtitle:'',button_text:'Shop Now',button_url:'/shop',image_url:'',mobile_image_url:'',start_at:'',end_at:'',sort_order:0,active:true};


async function uploadMedia(file,folder,bucket='product-media'){
  if(!supabase)throw new Error('Supabase is not configured.');
  if(!file)throw new Error('Please choose a file.');
  const ext=(file.name.split('.').pop()||'bin').toLowerCase();
  const safe=(file.name||'file').replace(/[^a-z0-9._-]/gi,'-').toLowerCase();
  const path=`${folder}/${Date.now()}-${Math.random().toString(36).slice(2,10)}-${safe||`file.${ext}`}`;
  const storage=supabase.storage.from(bucket);
  const{error}=await storage.upload(path,file,{upsert:false,cacheControl:'3600',contentType:file.type||undefined});
  if(error){
    const msg=String(error.message||error);
    if(/bucket|not found/i.test(msg)) throw new Error(`Storage bucket "${bucket}" পাওয়া যাচ্ছে না। Supabase migration SQL run করুন।`);
    if(/row-level security|policy|permission|not authorized/i.test(msg)) throw new Error(`Image upload permission denied. আপনার admin account-এর Storage permission ঠিক করতে Banner/Product Media migration SQL run করুন।`);
    throw new Error(`Image upload failed: ${msg}`);
  }
  const{data}=storage.getPublicUrl(path);
  if(!data?.publicUrl)throw new Error('Upload হয়েছে, কিন্তু public image URL পাওয়া যায়নি।');
  return data.publicUrl;
}

class AdminTabBoundary extends React.Component{constructor(p){super(p);this.state={error:null}}static getDerivedStateFromError(error){return{error}}componentDidCatch(error){console.error('Admin tab error:',error)}render(){if(this.state.error)return <div className="card"><h2>Admin section error</h2><p className="muted">এই section load করতে সমস্যা হয়েছে। অন্য tab ব্যবহার করুন বা page refresh করুন.</p><pre className="errorpre">{String(this.state.error?.message||this.state.error)}</pre><button className="btn" onClick={()=>this.setState({error:null})}>Try again</button></div>;return this.props.children}}

export default function Admin(){
  const initialTab=(()=>{try{const t=new URLSearchParams(location.search).get('tab');if(TABS.includes(t))return t;const saved=localStorage.getItem('flowget-admin-tab-v2');return TABS.includes(saved)?saved:'dashboard'}catch{return'dashboard'}})();
  const[user,setUser]=useState(null),[admin,setAdmin]=useState(false),[authReady,setAuthReady]=useState(false),[adminChecking,setAdminChecking]=useState(false),[tab,setTab]=useState(initialTab),[err,setErr]=useState(''),[menu,setMenu]=useState(false);
  useEffect(()=>{
    if(!supabase){setAuthReady(true);return;}
    let alive=true;
    const verify=async(session)=>{
      const u=session?.user||null;
      if(!alive)return;
      setUser(u);
      if(!u){setAdmin(false);setAdminChecking(false);setAuthReady(true);return;}
      setAdminChecking(true);
      const{data:a,error}=await supabase.rpc('is_admin');
      if(!alive)return;
      setAdmin(!error&&Boolean(a));
      setAdminChecking(false);
      setAuthReady(true);
    };
    supabase.auth.getSession().then(({data})=>verify(data.session));
    const{data:sub}=supabase.auth.onAuthStateChange((_e,s)=>{verify(s)});
    return()=>{alive=false;sub.subscription.unsubscribe()};
  },[]);
  useEffect(()=>{const onPop=()=>{const t=new URLSearchParams(location.search).get('tab');setTab(TABS.includes(t)?t:'dashboard')};addEventListener('popstate',onPop);return()=>removeEventListener('popstate',onPop)},[]);
  useEffect(()=>{try{localStorage.setItem('flowget-admin-tab-v2',tab)}catch{}},[tab]);
  if(!supabase)return <div className="container"><div className="card"><h1>Admin Setup</h1><p>Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to your environment.</p></div></div>;
  if(!authReady||adminChecking)return <div className="container"><div className="card adminloading"><div className="spinner"/><h2>Loading Admin…</h2><p className="muted">Checking secure admin session.</p></div></div>;
  if(!user)return <AdminLogin/>;
  if(!admin)return <div className="container"><div className="card admin-denied"><h1>Access denied</h1><p>Your account is signed in, but it is not an approved FlowGet administrator.</p><button className="btn" onClick={()=>supabase.auth.signOut()}>Sign out</button></div></div>;
  return <div className="adminwrap">
    <aside className={`adminnav ${menu?'open':''}`}>
      <div className="adminnavtop"><h2>FlowGet Admin</h2><button className="adminmenubtn" onClick={()=>setMenu(!menu)} aria-label="Toggle admin menu">{menu?<X/>:<Menu/>}</button></div>
      <div className="adminnavlinks">{TABS.map(x=><button type="button" className={tab===x?'active':''} onClick={()=>{setErr('');setTab(x);setMenu(false);const u=new URL(location.href);u.searchParams.set('tab',x);history.pushState({},'',u.pathname+'?'+u.searchParams.toString())}} key={x}>{x[0].toUpperCase()+x.slice(1)}</button>)}<button type="button" onClick={()=>supabase.auth.signOut()}>Logout</button></div>
    </aside>
    <section className="adminmain"><div className="adminhead"><h1>{tab[0].toUpperCase()+tab.slice(1)}</h1>{err&&<div className="notice" role="alert">{err}</div>}</div><AdminTabBoundary>{tab==='dashboard'?<Dashboard/>:tab==='settings'?<Settings/>:tab==='products'?<Products setErr={setErr}/>:tab==='categories'?<Categories setErr={setErr}/>:tab==='orders'?<Orders setErr={setErr}/>:tab==='coupons'?<Coupons setErr={setErr}/>:<Banners setErr={setErr}/>}</AdminTabBoundary></section>
  </div>
}
function AdminLogin(){const[e,setE]=useState({email:'',password:''}),[err,setErr]=useState(''),[busy,setBusy]=useState(false);return <div className="container"><div className="card adminlogin"><h1>🔐 FlowGet Admin</h1><p className="muted">Phone থেকে product ও order manage করুন।</p><form onSubmit={async x=>{x.preventDefault();setErr('');setBusy(true);const{error}=await supabase.auth.signInWithPassword(e);setBusy(false);if(error)setErr(error.message.includes('Invalid login')?'Invalid email or password.':error.message)}}><Text f="email" type="email" v={e.email} set={v=>setE({...e,email:v})}/><Text f="password" type="password" v={e.password} set={v=>setE({...e,password:v})}/><button className="btn" disabled={busy}>{busy?'Logging in…':'Login'}</button>{err&&<div className="notice" role="alert">{err}</div>}</form></div></div>}
function Dashboard(){
  const[s,setS]=useState({orders:0,products:0,pending:0,sales:0,activeVisitors:0,events:0,recent:[]}),[loading,setLoading]=useState(true);
  const load=async()=>{
    const since=new Date(Date.now()-30*60*1000).toISOString();
    const recentSince=new Date(Date.now()-24*60*60*1000).toISOString();
    const[o,p,sess,events]=await Promise.all([
      supabase.from('orders').select('id,total,status'),
      supabase.from('products').select('id'),
      supabase.from('visitor_sessions').select('id,started_at,last_path,device_type,referrer').gte('started_at',since).order('started_at',{ascending:false}).limit(100),
      supabase.from('analytics_events').select('id,event_name,path,session_id,created_at').gte('created_at',recentSince).order('created_at',{ascending:false}).limit(20)
    ]);
    const rows=o.data||[]; const visitors=sess.data||[];
    setS({orders:rows.length,products:(p.data||[]).length,pending:rows.filter(x=>String(x.status).toLowerCase()==='pending').length,sales:rows.filter(x=>String(x.status).toLowerCase()!=='cancelled').reduce((a,x)=>a+Number(x.total||0),0),activeVisitors:visitors.length,events:(events.data||[]).length,recent:visitors.slice(0,8)});
    if(o.error||p.error||sess.error||events.error){console.warn('Admin dashboard load:',o.error||p.error||sess.error||events.error)}
    setLoading(false);
  };
  useEffect(()=>{load();const id=setInterval(load,60000);return()=>clearInterval(id)},[]);
  if(loading)return <div className="admincards"><div className="stat">Loading…</div><div className="stat">Loading…</div><div className="stat">Loading…</div><div className="stat">Loading…</div></div>;
  return <>
    <div className="admincards"><div className="stat">Orders<strong>{s.orders}</strong></div><div className="stat">Pending<strong>{s.pending}</strong></div><div className="stat">Products<strong>{s.products}</strong></div><div className="stat">Sales<strong>৳{s.sales}</strong></div><div className="stat visitorstat">Active visitors<strong>{s.activeVisitors}</strong><small>last 30 min</small></div><div className="stat visitorstat">Events<strong>{s.events}</strong><small>last 24 hours</small></div></div>
    <div className="card visitorpanel"><div className="panelhead"><div><h2>Visitor Activity</h2><p className="muted">Live-ish activity from the last 30 minutes.</p></div><button className="btn smallbtn" onClick={load}>Refresh</button></div>{s.recent.length?<div className="visitorlist">{s.recent.map(v=><div className="visitorrow" key={v.id}><span className="dot"/><div><strong>{v.device_type||'Visitor'}</strong><small>{v.last_path||'/'} · {new Date(v.started_at).toLocaleTimeString()}</small></div></div>)}</div>:<div className="empty">No visitor activity yet. Once the tracking code is deployed, new visits will appear here.</div>}</div>
  </>
}
function specificationsToText(value){if(!value||typeof value!=='object')return '';if(typeof value.details==='string')return value.details;return Object.entries(value).map(([k,v])=>`${k}: ${String(v??'')}`).join('\n')}
function Products({setErr}){
  const[data,setData]=useState([]),[cats,setCats]=useState([]),[editing,setEditing]=useState(null),[form,setForm]=useState(emptyProduct),[saving,setSaving]=useState(false),[uploading,setUploading]=useState(false),[galleryUrls,setGalleryUrls]=useState([]),[existingGallery,setExistingGallery]=useState([]),[specsText,setSpecsText]=useState('');
  const load=()=>Promise.all([getProducts({}),getCategories()]).then(([p,c])=>{setData(p);setCats(c)}).catch(e=>setErr(e.message));
  useEffect(()=>{
    load();
    try{
      const raw=localStorage.getItem('flowget-admin-product-edit-v2');
      if(raw){
        const draft=JSON.parse(raw);
        if(draft?.id){
          setEditing(draft.id);
          setForm({...emptyProduct,...(draft.form||{}),category_id:draft.form?.category_id||'',price:draft.form?.price??'',discount_price:draft.form?.discount_price??'',stock:draft.form?.stock??0,video_url:draft.form?.video_url||'',short_description:draft.form?.short_description||''});
          setSpecsText(specificationsToText(draft.form?.specifications||draft.specs));
          setGalleryUrls(Array.isArray(draft.galleryUrls)?draft.galleryUrls:[]);
          setExistingGallery(Array.isArray(draft.existingGallery)?draft.existingGallery:[]);
        }
      }
    }catch{}
  },[]);
  useEffect(()=>{
    if(!editing)return;
    try{localStorage.setItem('flowget-admin-product-edit-v2',JSON.stringify({id:editing,form,specsText,galleryUrls,existingGallery}))}catch{}
  },[editing,form,specsText,galleryUrls,existingGallery]);
  const clearProductDraft=()=>{try{localStorage.removeItem('flowget-admin-product-edit-v2')}catch{}};
  const save=async e=>{e.preventDefault();setErr('');setSaving(true);try{
    const cleanSpecText=String(specsText||'').trim();
    const payload={...form,price:Number(form.price),discount_price:form.discount_price===''?null:Number(form.discount_price),stock:Number(form.stock),category_id:form.category_id||null,sku:form.sku||null,video_url:form.video_url||null,short_description:String(form.short_description||'').trim()||null,specifications:cleanSpecText?{details:cleanSpecText}:{}};
    const r=editing?await supabase.from('products').update(payload).eq('id',editing):await supabase.from('products').insert(payload).select('id').single();
    if(r.error)throw r.error;
    const productId=editing||r.data?.id;
    if(galleryUrls.length&&productId){const{error}=await supabase.from('product_images').insert(galleryUrls.map((url,i)=>({product_id:productId,url,sort_order:existingGallery.length+i+10})));if(error)throw error}
    clearProductDraft();setEditing(null);setForm(emptyProduct);setGalleryUrls([]);setExistingGallery([]);setSpecsText('');await load();
  }catch(e){setErr(e.message)}finally{setSaving(false)}};
  const edit=p=>{
    setEditing(p.id);setForm({...emptyProduct,...p,category_id:p.category_id||'',price:p.price??'',discount_price:p.discount_price??'',stock:p.stock??0,video_url:p.video_url||'',short_description:p.short_description||''});
    setSpecsText(specificationsToText(p.specifications));
    setGalleryUrls([]);setExistingGallery((p.product_images||[]).slice().sort((a,b)=>Number(a.sort_order||0)-Number(b.sort_order||0)));
  };
  const handleImage=async(e,multiple=false)=>{const files=[...(e.target.files||[])];if(!files.length)return;setUploading(true);setErr('');try{
    const urls=[];for(const file of files){if(!file.type.startsWith('image/'))throw new Error('Only image files are allowed.');if(file.size>8*1024*1024)throw new Error(`${file.name}: image must be 8MB or smaller.`);urls.push(await uploadMedia(file,'products'))}
    if(multiple){
      if(editing){const rows=urls.map((url,i)=>({product_id:editing,url,sort_order:existingGallery.length+i+10}));const{error}=await supabase.from('product_images').insert(rows);if(error)throw error;setExistingGallery(g=>[...g,...rows]);}
      else setGalleryUrls(g=>[...g,...urls]);
      if(!form.main_image)setForm(f=>({...f,main_image:urls[0]}));
    }else{
      const url=urls[0];
      setForm(f=>({...f,main_image:url}));
      if(editing){const{error}=await supabase.from('products').update({main_image:url}).eq('id',editing);if(error)throw error;}
    }
  }catch(e){setErr(e.message)}finally{setUploading(false);e.target.value=''}};
  const removeGallery=async(url)=>{if(!editing)return;setErr('');try{const{error}=await supabase.from('product_images').delete().eq('product_id',editing).eq('url',url);if(error)throw error;setExistingGallery(g=>g.filter(x=>x.url!==url))}catch(e){setErr(e.message)}};
  const handleVideo=async e=>{const file=e.target.files?.[0];if(!file)return;setUploading(true);setErr('');try{if(!file.type.startsWith('video/'))throw new Error('Please choose a video file.');if(file.size>50*1024*1024)throw new Error('Video must be 50MB or smaller.');const url=await uploadMedia(file,'videos');setForm(f=>({...f,video_url:url}));if(editing){const{error}=await supabase.from('products').update({video_url:url}).eq('id',editing);if(error)throw error}}catch(e){setErr(e.message)}finally{setUploading(false);e.target.value=''}};
  const reset=()=>{clearProductDraft();setEditing(null);setForm(emptyProduct);setGalleryUrls([]);setExistingGallery([]);setSpecsText('')};
  return <><Editor title={editing?'Edit Product':'Add Product'} onSubmit={save} onCancel={reset} saving={saving} fields={<>
    <Text f="name" v={form.name} set={v=>setForm(f=>({...f,name:v}))}/><Text f="slug" v={form.slug} set={v=>setForm(f=>({...f,slug:v}))}/><Text f="sku" v={form.sku||''} set={v=>setForm(f=>({...f,sku:v}))}/><Text f="brand" v={form.brand||''} set={v=>setForm(f=>({...f,brand:v}))}/>
    <div className="field"><label>Category</label><select value={form.category_id} onChange={e=>setForm(f=>({...f,category_id:e.target.value}))}><option value="">No category</option>{cats.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
    <div className="two"><Text f="price" type="number" v={form.price} set={v=>setForm(f=>({...f,price:v}))}/><Text f="discount_price" type="number" v={form.discount_price} set={v=>setForm(f=>({...f,discount_price:v}))}/></div><Text f="stock" type="number" v={form.stock} set={v=>setForm(f=>({...f,stock:v}))}/>
    <div className="uploadgrid productuploads">
      <div className="uploadbox"><label className="uploadlabel"><ImageIcon size={18}/> <span>Main product image</span><input type="file" accept="image/*" onChange={handleImage}/></label><button type="button" className="mobileuploadbtn" onClick={e=>e.currentTarget.previousElementSibling.querySelector('input').click()}>🖼️ {editing?'Replace main image':'Choose main image'}</button><small>JPG, PNG, WebP, GIF · max 8MB</small>{form.main_image&&<img className="uploadpreview" src={form.main_image} alt="Product preview"/>}</div>
      <div className="uploadbox"><label className="uploadlabel"><ImageIcon size={18}/> <span>Gallery images</span><input type="file" accept="image/*" multiple onChange={e=>handleImage(e,true)}/></label><button type="button" className="mobileuploadbtn" onClick={e=>e.currentTarget.previousElementSibling.querySelector('input').click()}>🖼️ Choose gallery photos</button><small>Mobile-eo multiple photo select/upload kora jabe · max 8MB each</small>{(existingGallery.length>0||galleryUrls.length>0)&&<div className="gallerypreviews">{existingGallery.map((g,i)=><div className="gallerythumb" key={g.id||g.url+i}><img src={g.url} alt={`Gallery ${i+1}`}/><button type="button" onClick={()=>removeGallery(g.url)} aria-label="Remove gallery image">×</button></div>)}{galleryUrls.map((u,i)=><div className="gallerythumb" key={u+i}><img src={u} alt={`New gallery ${i+1}`}/></div>)}</div>}</div>
      <div className="uploadbox"><label className="uploadlabel"><Video size={18}/> <span>Product video</span><input type="file" accept="video/mp4,video/webm,video/quicktime" onChange={handleVideo}/></label><button type="button" className="mobileuploadbtn" onClick={e=>e.currentTarget.previousElementSibling.querySelector('input').click()}>🎥 Choose video</button><small>MP4/WebM/MOV · max 50MB</small></div>
    </div>
    <Text f="main_image_url" v={form.main_image||''} set={v=>setForm(f=>({...f,main_image:v}))}/><Text f="video_url" v={form.video_url||''} set={v=>setForm(f=>({...f,video_url:v}))}/>
    <div className="field"><label>Short Description <small>(Optional — price-এর নিচে ছোট summary)</small></label><textarea rows="3" maxLength={240} placeholder="যেমন: 3-speed wireless rechargeable coffee mixer for quick foam." value={form.short_description||''} onChange={e=>setForm(f=>({...f,short_description:e.target.value}))}/></div>
    <div className="field"><label>Description</label><textarea rows="7" value={form.description||''} onChange={e=>setForm(f=>({...f,description:e.target.value}))}/></div>
    <div className="specbox simple-specbox"><div className="spechead"><div><label>Specifications</label><small>সাধারণ text হিসেবে লিখুন। প্রতিটি specification নতুন লাইনে দিন। যেমন: Material: ABS</small></div></div><textarea rows="7" placeholder={'Material: ABS\nBattery: 1200mAh\nPower: 3.7V 6W\nModel: MC/D-311'} value={specsText} onChange={e=>setSpecsText(e.target.value)}/></div>
    <label className="check"><input type="checkbox" checked={form.active} onChange={e=>setForm(f=>({...f,active:e.target.checked}))}/> Active</label>{uploading&&<div className="notice">Uploading media… please wait.</div>}
  </>}/><Table columns={['name','sku','price','stock','active']} data={data} onEdit={p=>edit(p)} onDelete={async p=>{if(confirm(`Delete ${p.name}?`)){const{error}=await supabase.from('products').delete().eq('id',p.id);if(error)setErr(error.message);else load()}}}/></>
}
function Categories({setErr}){const[data,setData]=useState([]),[editing,setEditing]=useState(null),[form,setForm]=useState(emptyCategory);const load=()=>getCategories().then(setData).catch(e=>setErr(e.message));useEffect(()=>{load()},[]);const save=async e=>{e.preventDefault();const payload={...form,sort_order:Number(form.sort_order||0)};const{error}=editing?await supabase.from('categories').update(payload).eq('id',editing):await supabase.from('categories').insert(payload);if(error)setErr(error.message);else{setEditing(null);setForm(emptyCategory);load()}};return <><Editor title={editing?'Edit Category':'Add Category'} onSubmit={save} onCancel={()=>{setEditing(null);setForm(emptyCategory)}} fields={<><Text f="name" v={form.name} set={v=>setForm(f=>({...f,name:v}))}/><Text f="slug" v={form.slug} set={v=>setForm(f=>({...f,slug:v}))}/><Text f="icon" v={form.icon} set={v=>setForm(f=>({...f,icon:v}))}/><Text f="sort_order" type="number" v={form.sort_order} set={v=>setForm(f=>({...f,sort_order:v}))}/><div className="field"><label>Description</label><textarea value={form.description||''} onChange={e=>setForm(f=>({...f,description:e.target.value}))}/></div><label className="check"><input type="checkbox" checked={form.active} onChange={e=>setForm({...form,active:e.target.checked})}/> Active</label></>}/><Table columns={['name','slug','sort_order','active']} data={data} onEdit={p=>{setEditing(p.id);setForm({...emptyCategory,...p})}} onDelete={async p=>{if(confirm(`Delete ${p.name}?`)){const{error}=await supabase.from('categories').delete().eq('id',p.id);if(error)setErr(error.message);else load()}}}/></>}
function Orders({setErr}){const[data,setData]=useState([]),[loading,setLoading]=useState(true),[busy,setBusy]=useState('');const load=async()=>{try{const{data,error}=await supabase.from('orders').select('*').order('created_at',{ascending:false}).limit(200);if(error)throw error;setData(data||[])}catch(e){setErr(e.message)}finally{setLoading(false)}};useEffect(()=>{load()},[]);const update=async(id,status)=>{setBusy(id);setErr('');try{if(status==='Cancelled'){const{error}=await supabase.rpc('cancel_order_secure',{p_order_uuid:id});if(error)throw error}else{const{error}=await supabase.rpc('update_order_status_secure',{p_order_uuid:id,p_status:status});if(error)throw error}await load()}catch(e){setErr(e.message)}finally{setBusy('')}};if(loading)return <div className="card"><p>Loading orders…</p></div>;return <div className="tablewrap"><table><thead><tr>{['order_id','customer_name','phone','subtotal','coupon','discount','delivery','total','status','created_at'].map(x=><th key={x}>{x}</th>)}</tr></thead><tbody>{data.map(o=><tr key={o.id}><td>{o.order_id}</td><td>{o.customer_name}</td><td>{o.phone}</td><td>৳{Number(o.subtotal||0)}</td><td>{o.coupon_code||'—'}</td><td>{Number(o.discount||0)>0?<span style={{color:'#16a34a'}}>-৳{Number(o.discount||0)}</span>:'—'}</td><td>৳{Number(o.delivery_charge||0)}</td><td><strong>৳{Number(o.total||0)}</strong></td><td><select value={o.status||'Pending'} disabled={busy===o.id} onChange={e=>update(o.id,e.target.value)}>{['Pending','Confirmed','Processing','Shipped','Delivered','Cancelled'].map(x=><option key={x}>{x}</option>)}</select></td><td>{new Date(o.created_at).toLocaleString()}</td></tr>)}</tbody></table></div>}
function Coupons({setErr}){const[data,setData]=useState([]),[editing,setEditing]=useState(null),[form,setForm]=useState(emptyCoupon);const load=()=>supabase.from('coupons').select('*').order('created_at',{ascending:false}).then(({data,error})=>{if(error)setErr(error.message);else setData(data||[])});useEffect(()=>{load()},[]);const save=async e=>{e.preventDefault();const payload={...form,code:form.code.trim().toUpperCase(),discount_value:Number(form.discount_value),min_order:Number(form.min_order||0),max_discount:form.max_discount===''?null:Number(form.max_discount),usage_limit:form.usage_limit===''?null:Number(form.usage_limit),per_customer_limit:form.per_customer_limit===''?null:Number(form.per_customer_limit),start_at:form.start_at||null,expires_at:form.expires_at||null};const legacyPayload={...payload,value:Number(form.discount_value)};let result=editing?await supabase.from('coupons').update(legacyPayload).eq('id',editing):await supabase.from('coupons').insert(legacyPayload);let error=result.error;if(error&&/column .*value.*does not exist|could not find the .*value.*column/i.test(String(error.message||''))){result=editing?await supabase.from('coupons').update(payload).eq('id',editing):await supabase.from('coupons').insert(payload);error=result.error}if(error)setErr(error.message);else{setEditing(null);setForm(emptyCoupon);load()}};return <><Editor title={editing?'Edit Coupon':'Add Coupon'} onSubmit={save} onCancel={()=>{setEditing(null);setForm(emptyCoupon)}} fields={<><Text f="code" v={form.code} set={v=>setForm(f=>({...f,code:v}))}/><div className="two"><div className="field"><label>Type</label><select value={form.coupon_type} onChange={e=>setForm(f=>({...f,coupon_type:e.target.value}))}><option>percentage</option><option>fixed</option></select></div><Text f="discount_value" type="number" v={form.discount_value} set={v=>setForm({...form,discount_value:v})}/></div><div className="two"><Text f="min_order" type="number" v={form.min_order} set={v=>setForm({...form,min_order:v})}/><Text f="max_discount" type="number" v={form.max_discount} set={v=>setForm({...form,max_discount:v})}/></div><div className="two"><Text f="usage_limit" type="number" v={form.usage_limit} set={v=>setForm({...form,usage_limit:v})}/><Text f="per_customer_limit" type="number" v={form.per_customer_limit} set={v=>setForm({...form,per_customer_limit:v})}/></div><label className="check"><input type="checkbox" checked={form.active} onChange={e=>setForm({...form,active:e.target.checked})}/> Active</label></>}/><Table columns={['code','coupon_type','discount_value','usage_limit','per_customer_limit','active']} data={data} onEdit={p=>{setEditing(p.id);setForm({...emptyCoupon,...p})}} onDelete={async p=>{if(confirm(`Delete ${p.code}?`)){const{error}=await supabase.from('coupons').delete().eq('id',p.id);if(error)setErr(error.message);else load()}}}/></>}
function Banners({setErr}){const[data,setData]=useState([]),[editing,setEditing]=useState(null),[form,setForm]=useState(emptyBanner),[loading,setLoading]=useState(true),[saving,setSaving]=useState(false),[uploading,setUploading]=useState(false);const load=async()=>{try{const{data,error}=await supabase.from('banners').select('*').order('sort_order');if(error)throw error;setData(data||[])}catch(e){setErr(e.message)}finally{setLoading(false)}};useEffect(()=>{load()},[]);const handleBannerImage=async(e,field)=>{const file=e.target.files?.[0];if(!file)return;setUploading(true);setErr('');try{if(!file.type.startsWith('image/'))throw new Error('Please choose an image file.');const url=await uploadMedia(file,'banners','banner-media');setForm(f=>({...f,[field]:url}))}catch(e){setErr(e.message)}finally{setUploading(false);e.target.value=''}};const save=async e=>{e.preventDefault();setSaving(true);setErr('');try{if(!form.image_url)throw new Error('Main banner image is required. Upload an image or paste an image URL.');const payload={...form,sort_order:Number(form.sort_order||0),start_at:form.start_at||null,end_at:form.end_at||null};const{error}=editing?await supabase.from('banners').update(payload).eq('id',editing):await supabase.from('banners').insert(payload);if(error)throw error;setEditing(null);setForm(emptyBanner);await load()}catch(e){setErr(e.message)}finally{setSaving(false)}};if(loading)return <div className="card"><p>Loading banners…</p></div>;return <><Editor title={editing?'Edit Banner':'Add Banner'} onSubmit={save} onCancel={()=>{setEditing(null);setForm(emptyBanner)}} saving={saving} fields={<><Text f="title" v={form.title} set={v=>setForm(f=>({...f,title:v}))}/><Text f="subtitle" v={form.subtitle} set={v=>setForm(f=>({...f,subtitle:v}))}/><Text f="button_text" v={form.button_text} set={v=>setForm(f=>({...f,button_text:v}))}/><Text f="button_url" v={form.button_url} set={v=>setForm(f=>({...f,button_url:v}))}/><div className="uploadgrid banneruploads"><div className="uploadbox"><label><ImageIcon size={18}/> Main banner image<input type="file" accept="image/*" onChange={e=>handleBannerImage(e,'image_url')}/></label><small>Desktop / main banner image</small>{form.image_url&&<img className="uploadpreview" src={form.image_url} alt="Banner preview"/>}</div><div className="uploadbox"><label><ImageIcon size={18}/> Mobile banner image<input type="file" accept="image/*" onChange={e=>handleBannerImage(e,'mobile_image_url')}/></label><small>Optional mobile-specific image</small>{form.mobile_image_url&&<img className="uploadpreview" src={form.mobile_image_url} alt="Mobile banner preview"/>}</div></div><Text f="image_url" v={form.image_url} set={v=>setForm(f=>({...f,image_url:v}))}/><Text f="mobile_image_url" v={form.mobile_image_url} set={v=>setForm(f=>({...f,mobile_image_url:v}))}/>{uploading&&<div className="notice">Uploading banner image…</div>}<Text f="sort_order" type="number" v={form.sort_order} set={v=>setForm(f=>({...f,sort_order:v}))}/><label className="check"><input type="checkbox" checked={form.active} onChange={e=>setForm(f=>({...f,active:e.target.checked}))}/> Active</label></>}/><Table columns={['title','button_url','sort_order','active']} data={data} onEdit={p=>{setEditing(p.id);setForm({...emptyBanner,...p})}} onDelete={async p=>{if(confirm('Delete banner?')){const{error}=await supabase.from('banners').delete().eq('id',p.id);if(error)setErr(error.message);else load()}}}/></>}
function Settings(){const[s,setS]=useState({});useEffect(()=>{getSettings().then(setS)},[]);const save=async()=>{const payload={...s,delivery_dhaka:Number(s.delivery_dhaka),delivery_outside:Number(s.delivery_outside),updated_at:new Date().toISOString()};const{error}=await supabase.from('website_settings').upsert(payload);if(error)alert(error.message);else setS(payload)};return <div className="card" style={{maxWidth:760}}><h2>Website Settings</h2>{['store_name','tagline','phone','email','browser_title','meta_description','search_placeholder','footer_about','primary','primary_hover','delivery_dhaka','delivery_outside'].map(k=><Text key={k} f={k} v={s[k]??''} set={v=>setS(prev=>({...prev,[k]:v}))}/>)}<button className="btn" onClick={save}>Save Settings</button></div>}
function Text({f,v,set,type='text'}){return <div className="field"><label>{f.replaceAll('_',' ')}</label><input type={type} value={v??''} onChange={e=>set(e.target.value)}/></div>}
function Editor({title,onSubmit,onCancel,fields,saving=false}){return <form className="card admineditor" onSubmit={onSubmit}><div className="admineditorhead"><h2>{title}</h2><button type="button" onClick={onCancel}>Reset</button></div>{fields}<button className="btn" disabled={saving}>{saving?'Saving…':'Save'}</button></form>}
function Table({columns,data,onEdit,onDelete}){return <div className="tablewrap"><table><thead><tr>{columns.map(x=><th key={x}>{x}</th>)}<th>actions</th></tr></thead><tbody>{data.map(r=><tr key={r.id}>{columns.map(k=><td key={k}>{String(r[k]??'').slice(0,80)}</td>)}<td><div className="tableactions"><button onClick={()=>onEdit(r)}>Edit</button><button onClick={()=>onDelete(r)}>Delete</button></div></td></tr>)}{!data.length&&<tr><td colSpan={columns.length+1}>No records.</td></tr>}</tbody></table></div>}
