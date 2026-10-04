import React,{useEffect,useState}from'react';
import{getProduct,getProductImages,getProductReviews,getProducts,submitReview,uploadReviewPhoto}from'../lib/store';
import{addCart}from'../lib/cart';
import{ShoppingCart,Minus,Plus,Star,Image as ImageIcon,Send}from'lucide-react';
import{useNavigate}from'../components/Layout';
import ProductCard from'../components/ProductCard';

function Stars({value=0,size=17}){return <span className="reviewstars" aria-label={`${value} out of 5 stars`}>{[1,2,3,4,5].map(n=><Star key={n} size={size} fill={n<=Number(value)?'currentColor':'none'}/>)}</span>}

function Reviews({product}){
  const[reviews,setReviews]=useState([]);
  const[loading,setLoading]=useState(true);
  const[name,setName]=useState('');
  const[rating,setRating]=useState(5);
  const[text,setText]=useState('');
  const[file,setFile]=useState(null);
  const[preview,setPreview]=useState('');
  const[busy,setBusy]=useState(false);
  const[msg,setMsg]=useState('');
  const[err,setErr]=useState('');
  const load=async()=>{try{setLoading(true);setReviews(await getProductReviews(product.id))}catch(e){console.warn('Review load:',e)}finally{setLoading(false)}};
  useEffect(()=>{load();return()=>{if(preview)URL.revokeObjectURL(preview)}},[product.id]);
  const chooseFile=e=>{
    const f=e.target.files?.[0]||null;
    setErr('');
    if(!f){setFile(null);setPreview('');return}
    if(!['image/jpeg','image/png','image/webp'].includes(f.type)){setErr('শুধু JPG, PNG বা WebP ছবি দেওয়া যাবে।');return}
    if(f.size>5*1024*1024){setErr('ছবির সাইজ সর্বোচ্চ 5MB হতে হবে।');return}
    setFile(f);setPreview(URL.createObjectURL(f));
  };
  const submit=async e=>{
    e.preventDefault();setErr('');setMsg('');
    const cleanName=name.trim(),cleanText=text.trim();
    if(cleanName.length<2)return setErr('আপনার নাম লিখুন।');
    if(cleanText.length<5)return setErr('কমপক্ষে 5 অক্ষরের review লিখুন।');
    if(!rating)return setErr('একটি rating দিন.');
    setBusy(true);
    try{
      let photoUrl=null;
      if(file)photoUrl=await uploadReviewPhoto(file,product.id);
      await submitReview({productId:product.id,customerName:cleanName,rating,reviewText:cleanText,photoUrl});
      setName('');setRating(5);setText('');setFile(null);setPreview('');
      setMsg('আপনার মতামত পাঠানোর জন্য ধন্যবাদ!');
    }catch(e){setErr(e?.message||'Review submit করা যায়নি।')}
    finally{setBusy(false)}
  };
  return <section className="reviews-section" id="reviews">
    <div className="reviews-head">
      <div><h2>Customer Reviews</h2><p className="muted">অন্য ক্রেতাদের অভিজ্ঞতা দেখুন এবং আপনার অভিজ্ঞতাও শেয়ার করুন।</p></div>
      <div className="review-summary"><Stars value={product.rating||0}/><strong>{Number(product.rating||0).toFixed(1)}</strong><span>{product.review_count||reviews.length} reviews</span></div>
    </div>
    <div className="review-form card">
      <h3>আপনার Review দিন</h3>
      <form onSubmit={submit}>
        <div className="review-form-grid">
          <label>Name<input value={name} onChange={e=>setName(e.target.value)} maxLength={80} placeholder="আপনার নাম" required/></label>
          <div><span className="fieldlabel">Rating</span><div className="rating-picker">{[1,2,3,4,5].map(n=><button key={n} type="button" className={n<=rating?'selected':''} onClick={()=>setRating(n)} aria-label={`${n} star`}><Star size={28} fill={n<=rating?'currentColor':'none'}/></button>)}</div></div>
        </div>
        <label>Review<textarea value={text} onChange={e=>setText(e.target.value)} maxLength={1000} rows={4} placeholder="পণ্যটি কেমন লেগেছে লিখুন..." required/></label>
        <div className="review-photo-row">
          <label className="uploadlabel review-upload"><ImageIcon size={18}/> <span>{file?'ছবি পরিবর্তন করুন':'Customer photo যোগ করুন (optional)'}</span><input type="file" accept="image/jpeg,image/png,image/webp" onChange={chooseFile}/></label>
          {preview&&<div className="review-preview"><img src={preview} alt="Review preview"/><button type="button" onClick={()=>{setFile(null);setPreview('')}}>×</button></div>}
        </div>
        {err&&<div className="notice" role="alert">{err}</div>}
        {msg&&<div className="notice successnotice">{msg}</div>}
        <button className="btn" disabled={busy}>{busy?<><span className="buttonspinner"/>Submitting…</>:<><Send size={17}/> Review Submit করুন</>}</button>
      </form>
    </div>
    {loading?<div className="empty">Reviews loading…</div>:reviews.length?<div className="review-list">{reviews.map(r=><article className="review-item" key={r.id}>
      <div className="review-top"><div><strong>{r.customer_name||'Customer'}</strong><Stars value={r.rating}/></div><time>{new Date(r.created_at).toLocaleDateString()}</time></div>
      <p>{r.review_text}</p>
      {r.photo_url&&<a href={r.photo_url} target="_blank" rel="noreferrer"><img className="review-photo" src={r.photo_url} alt={`Review by ${r.customer_name||'customer'}`}/></a>}
    </article>)}</div>:<div className="empty">এখনও কোনো approved review নেই। প্রথম reviewটি আপনিই দিতে পারেন।</div>}
  </section>
}

export default function Product({slug}){
  const navigate=useNavigate();
  const[p,setP]=useState(null),[loading,setLoading]=useState(true),[qty,setQty]=useState(1),[related,setRelated]=useState([]),[activeImage,setActiveImage]=useState('');
  useEffect(()=>{let alive=true;setLoading(true);setP(null);setRelated([]);
    getProduct(slug).then(async x=>{
      if(!alive)return;if(!x){setP(null);setLoading(false);return}
      setP(x);setLoading(false);setActiveImage(x?.main_image||'');
      if(x){document.title=`${x.name} | FlowGet`;let meta=document.querySelector('meta[name=description]');if(!meta){meta=document.createElement('meta');meta.name='description';document.head.appendChild(meta)}meta.content=(x.meta_description||x.description||`${x.name} — buy online from FlowGet.`).slice(0,155)}
      const imagePromise=getProductImages(x.id).then(images=>{if(alive)setP(prev=>prev?{...prev,product_images:images}:prev)});
      if(x?.category_id)setRelated((await getProducts({category:x.category_id})).filter(y=>y.id!==x.id).slice(0,5));
      await imagePromise
    }).catch(()=>{if(alive){setP(null);setLoading(false)}});return()=>{alive=false}
  },[slug]);
  if(loading)return <div className="empty"><div style={{fontSize:18,fontWeight:700}}>Loading product…</div><div className="muted" style={{marginTop:8}}>Please wait a moment.</div></div>;
  if(!p)return <div className="empty">Product not found.</div>;
  const price=p.discount_price||p.price;
  const gallery=[...(p.main_image?[{url:p.main_image,sort_order:-1}]:[]),...((p.product_images||[]).sort((a,b)=>Number(a.sort_order||0)-Number(b.sort_order||0)))].filter((x,i,a)=>x.url&&a.findIndex(y=>y.url===x.url)===i);
  const specObj=p.specifications;
  // Specifications may come from Supabase as JSONB, plain TEXT, or a JSON
  // object that was previously saved into a TEXT column. Normalize all three
  // shapes before rendering so customers never see raw JSON such as
  // {\"details\":\"...\\n...\"}.
  const specsText=(()=>{
    const toText=value=>{
      if(value==null)return '';
      if(typeof value==='string'){
        const text=value.trim();
        if(!text)return '';
        try{
          const parsed=JSON.parse(text);
          if(parsed!==value)return toText(parsed);
        }catch{}
        return value.replace(/\\n/g,'\n');
      }
      if(typeof value!=='object')return String(value);
      if(typeof value.details==='string')return toText(value.details);
      return Object.entries(value)
        .filter(([k])=>k!=='short_description')
        .map(([k,v])=>`${k}: ${toText(v)}`)
        .filter(line=>line.trim())
        .join('\n');
    };
    return toText(specObj);
  })();
  return <div className="container">
    <div className="detail"><div className="gallery">{activeImage?<img src={activeImage} alt={p.name}/>:<div className="placeholder">FLOWGET</div>}{gallery.length>1&&<div className="thumbs">{gallery.map((g,i)=><button type="button" className={activeImage===g.url?'active':''} key={g.url+i} onClick={()=>setActiveImage(g.url)}><img src={g.url} alt={`${p.name} ${i+1}`}/></button>)}</div>}{p.video_url&&<video className="productvideo" src={p.video_url} controls playsInline preload="metadata"/>}</div>
      <div><div className="rating"><Star size={15} fill="currentColor"/> {Number(p.rating||0).toFixed(1)} ({p.review_count||0})</div><h1>{p.name}</h1><p className="muted">SKU: {p.sku||'—'}{p.brand?' · '+p.brand:''}</p><div className="price">৳{price}<span className="old">{p.discount_price&&'৳'+p.price}</span></div>{(p.specifications?.short_description||p.short_description)&&<p className="shortdescription">{p.specifications?.short_description||p.short_description}</p>}<p><b>{p.stock>0?`In stock: ${p.stock}`:'Out of stock'}</b></p>
        <div className="qty"><button onClick={()=>setQty(Math.max(1,qty-1))}><Minus size={16}/></button><span>{qty}</span><button onClick={()=>setQty(Math.min(p.stock||1,qty+1))}><Plus size={16}/></button></div>
        <div style={{marginTop:15,display:'flex',gap:10,flexWrap:'wrap'}}><button className="btn" disabled={!p.stock} onClick={()=>{addCart(p,qty);alert('Added to cart')}}><ShoppingCart size={18}/> Add to Cart</button><button className="btn" disabled={!p.stock} onClick={()=>{addCart(p,qty);navigate('/checkout')}}>Buy Now</button><button type="button" className="btn secondarybtn" onClick={async()=>{try{await navigator.clipboard.writeText(location.href);alert('Product link copied')}catch{alert(location.href)}}}>Copy product link</button></div>
      </div>
    </div>
    <section className="productinfo"><div className="productinfo-card" id="description"><h2>Product Description</h2><div className="productdescription">{p.description?<p>{p.description}</p>:<p>Quality product from FlowGet.</p>}</div></div><div className="productinfo-card" id="specifications"><h2>Specifications</h2>{specsText?<div className="productdescription">{specsText}</div>:<p className="muted">No specifications added for this product yet.</p>}</div></section>
    <Reviews product={p}/>
    {related.length>0&&<section className="section"><h2>Related Products</h2><div className="grid">{related.map(x=><ProductCard p={x} key={x.id}/>)}</div></section>}
  </div>
}
