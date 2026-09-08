import React,{useEffect,useMemo,useState}from'react';
import{getCart,clearCart}from'../lib/cart';
import{getSettings,placeOrder}from'../lib/store';
import{getBangladeshLocations}from'../data/bangladesh';
import{useNavigate}from'../components/Layout';

export default function Checkout(){
 const nav=useNavigate();
 const[c,setC]=useState(getCart());
 const[s,setS]=useState({delivery_dhaka:80,delivery_outside:140});
 const[locations,setLocations]=useState([]);
 const[locLoading,setLocLoading]=useState(true);
 const[locErr,setLocErr]=useState('');
 const[f,setF]=useState({name:'',phone:'',division:'',district:'',area:'',address:'',note:'',coupon:'',paymentMethod:'Cash on Delivery'});
 const[busy,setBusy]=useState(false),[err,setErr]=useState('');

 useEffect(()=>{getSettings().then(setS).catch(()=>{})},[]);
 useEffect(()=>{const sync=()=>setC(getCart());window.addEventListener('flowget-cart-updated',sync);return()=>window.removeEventListener('flowget-cart-updated',sync)},[]);
 useEffect(()=>{let alive=true;setLocLoading(true);getBangladeshLocations().then(x=>{if(alive)setLocations(x)}).catch(e=>{if(alive)setLocErr(e?.message||'ঠিকানার তালিকা লোড করা যায়নি।')}).finally(()=>alive&&setLocLoading(false));return()=>{alive=false}},[]);

 const division=locations.find(x=>x.bn_name===f.division||x.name===f.division);
 const districts=division?.districts||[];
 const district=districts.find(x=>x.bn_name===f.district||x.name===f.district);
 const upazilas=district?.upazilas||[];
 const sub=useMemo(()=>c.reduce((x,p)=>x+(Number(p.discount_price??p.price)||0)*Number(p.qty||0),0),[c]);
 const delivery=f.division==='ঢাকা'||f.division==='Dhaka'?Number(s.delivery_dhaka||0):Number(s.delivery_outside||0);

 const setField=(key,value,extra={})=>setF(x=>({...x,[key]:value,...extra}));
 const onDivision=e=>setField('division',e.target.value,{district:'',area:''});
 const onDistrict=e=>setField('district',e.target.value,{area:''});
 const submit=async e=>{
  e.preventDefault();setErr('');
  if(!c.length)return;
  if(!f.division||!f.district||!f.area){setErr('বিভাগ, জেলা ও উপজেলা নির্বাচন করুন।');return}
  const phone=f.phone.replace(/[\s-]/g,'');
  if(!/^01\d{9}$/.test(phone)){setErr('সঠিক বাংলাদেশি মোবাইল নম্বর দিন।');return}
  setBusy(true);
  try{const order=await placeOrder({...f,phone,deliveryArea:(f.division==='ঢাকা'||f.division==='Dhaka')?'Dhaka':'Outside Dhaka',items:c.map(p=>({product_id:p.id,quantity:Number(p.qty)}))});clearCart();sessionStorage.setItem('flowget_last_order',JSON.stringify(order));nav('/order-success')}
  catch(e){setErr(e?.message?.replace(/^.*?: /,'')||'অর্ডার সম্পন্ন করা যায়নি। আবার চেষ্টা করুন.')}
  finally{setBusy(false)}
 };

 if(!c.length)return <div className="container empty"><h2>আপনার কার্ট খালি</h2><button className="btn" onClick={()=>nav('/shop')}>শপিং করুন</button></div>;
 return <div className="container">
  <h1 className="pageTitle">অর্ডার সম্পন্ন করুন</h1>
  <div className="notice">আপনার সঠিক ঠিকানা নির্বাচন করলে দ্রুত ও নির্ভুলভাবে পণ্য ডেলিভারি করা সম্ভব হবে।</div>
  <div className="checkoutlayout">
   <form className="card" onSubmit={submit}>
    <h2 className="formtitle">ডেলিভারি তথ্য</h2>
    <div className="two">
     <div className="field"><label>আপনার নাম</label><input required value={f.name} onChange={e=>setField('name',e.target.value)} placeholder="পূর্ণ নাম লিখুন"/></div>
     <div className="field"><label>মোবাইল নম্বর</label><input required inputMode="tel" placeholder="01XXXXXXXXX" value={f.phone} onChange={e=>setField('phone',e.target.value)}/></div>
    </div>
    <div className="two">
     <div className="field"><label>বিভাগ</label><select required value={f.division} onChange={onDivision} disabled={locLoading}><option value="">{locLoading?'তালিকা লোড হচ্ছে...':'বিভাগ নির্বাচন করুন'}</option>{locations.map(x=><option key={x.name} value={x.bn_name}>{x.bn_name}</option>)}</select></div>
     <div className="field"><label>জেলা</label><select required value={f.district} onChange={onDistrict} disabled={!division||locLoading}><option value="">জেলা নির্বাচন করুন</option>{districts.map(x=><option key={x.name} value={x.bn_name}>{x.bn_name}</option>)}</select></div>
    </div>
    <div className="field"><label>উপজেলা / থানা</label><select required value={f.area} onChange={e=>setField('area',e.target.value)} disabled={!district||locLoading}><option value="">উপজেলা / থানা নির্বাচন করুন</option>{upazilas.map(x=><option key={x.name} value={x.bn_name}>{x.bn_name}</option>)}</select></div>
    {locErr&&<div className="notice" role="alert">{locErr} পেজ রিফ্রেশ করে আবার চেষ্টা করুন।</div>}
    <div className="field"><label>বিস্তারিত ঠিকানা</label><textarea required rows="3" value={f.address} onChange={e=>setField('address',e.target.value)} placeholder="বাড়ি/রোড/এলাকার বিস্তারিত ঠিকানা লিখুন"/></div>
    <div className="field"><label>কুপন কোড (যদি থাকে)</label><input value={f.coupon} onChange={e=>setField('coupon',e.target.value.toUpperCase())} placeholder="কুপন কোড লিখুন"/></div>
    <div className="field"><label>অর্ডার সংক্রান্ত নোট (ঐচ্ছিক)</label><textarea rows="2" value={f.note} onChange={e=>setField('note',e.target.value)} placeholder="যেমন: বিকেল ৫টার পরে ডেলিভারি চাই"/></div>
    <div className="field"><label>পেমেন্ট পদ্ধতি</label><div className="notice">ক্যাশ অন ডেলিভারি</div></div>
    {err&&<div className="notice" role="alert">{err}</div>}
    <button className="btn" disabled={busy||locLoading}>{busy?'অর্ডার দেওয়া হচ্ছে...':'অর্ডার নিশ্চিত করুন'}</button>
   </form>
   <div className="card summary"><h3>অর্ডারের সারাংশ</h3>{c.map(x=><p key={x.id}>{x.name} × {x.qty}<b>৳{(Number(x.discount_price??x.price)||0)*x.qty}</b></p>)}<hr/><p>পণ্যের মূল্য <b>৳{sub}</b></p><p>ডেলিভারি চার্জ <b>৳{delivery}</b></p><h2>সর্বমোট <span>৳{sub+delivery}</span></h2><small className="muted">চূড়ান্ত মূল্য, স্টক, কুপন ও ডেলিভারি চার্জ Supabase-এ নিরাপদভাবে পুনরায় যাচাই করা হবে।</small></div>
  </div>
 </div>
}
