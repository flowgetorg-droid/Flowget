import {supabase} from './supabase';
export const fallbackSettings={store_name:'FlowGet',tagline:'Smart products. Simple shopping.',phone:'',email:'',primary:'#f97316',primary_hover:'#ea580c',secondary:'#111827',delivery_dhaka:80,delivery_outside:140,currency:'৳'};
export async function getSettings(){if(!supabase)return fallbackSettings;const {data,error}=await supabase.from('website_settings').select('*').eq('id',true).maybeSingle();if(error)throw error;return data?{...fallbackSettings,...data}:fallbackSettings}
export async function getCategories(){if(!supabase)return[];const {data,error}=await supabase.from('categories').select('*').eq('active',true).order('sort_order');if(error)throw error;return data||[]}
export async function getProducts({category,search,sort='newest',minPrice,maxPrice,brand,available}={}){
  if(!supabase)return[];
  // Intentionally use select('*') with all filtering applied locally. This keeps
  // the product catalog independent of PostgREST relationship/schema-cache
  // knowledge about individual optional columns.
  const {data,error}=await supabase.from('products').select('*').limit(2000);
  if(error)throw error;
  let products=(data||[]).filter(p=>p.active===undefined||p.active===true);
  if(category)products=products.filter(p=>!p.category_id||String(p.category_id)===String(category));
  const term=String(search||'').trim().toLowerCase();
  if(term)products=products.filter(p=>[p.name,p.sku,p.brand].some(v=>String(v||'').toLowerCase().includes(term)));
  if(brand)products=products.filter(p=>String(p.brand||'')===String(brand));
  if(minPrice!==undefined&&minPrice!=='')products=products.filter(p=>Number(p.discount_price??p.price??0)>=Number(minPrice));
  if(maxPrice!==undefined&&maxPrice!=='')products=products.filter(p=>Number(p.discount_price??p.price??0)<=Number(maxPrice));
  if(available)products=products.filter(p=>Number(p.stock||0)>0);
  products.sort((a,b)=>{
    if(sort==='price_asc')return Number(a.discount_price??a.price??0)-Number(b.discount_price??b.price??0);
    if(sort==='price_desc')return Number(b.discount_price??b.price??0)-Number(a.discount_price??a.price??0);
    if(sort==='popular')return Number(b.review_count||0)-Number(a.review_count||0);
    return new Date(b.created_at||0)-new Date(a.created_at||0);
  });
  if(!products.length)return products;
  const ids=products.map(p=>p.id).filter(Boolean);
  const {data:images,error:imageError}=await supabase.from('product_images').select('id,product_id,url,sort_order').in('product_id',ids).order('sort_order',{ascending:true});
  if(imageError){console.warn('Product gallery load skipped:',imageError.message);return products.map(p=>({...p,product_images:[]}));}
  const byProduct={};
  (images||[]).forEach(img=>{(byProduct[img.product_id]||(byProduct[img.product_id]=[])).push(img)});
  return products.map(p=>({...p,product_images:byProduct[p.id]||[]}));
}
export async function getProduct(slug){
  if(!supabase)return null;
  const clean=decodeURIComponent(String(slug||'')).split('?')[0].split('#')[0].trim();
  if(!clean)return null;
  const {data,error}=await supabase.from('products').select('*').limit(2000);
  if(error)throw error;
  const key=clean.toLowerCase().replace(/[^a-z0-9]/g,'');
  const product=(data||[]).find(p=>{
    if(p.active===false)return false;
    const a=String(p.slug||'').toLowerCase().replace(/[^a-z0-9]/g,'');
    const b=String(p.sku||'').toLowerCase().replace(/[^a-z0-9]/g,'');
    const c=String(p.id||'').toLowerCase().replace(/[^a-z0-9]/g,'');
    return a===key||b===key||c===key;
  })||null;
  return product?{...product,product_images:[]}:null;
}
export async function getProductImages(productId){
  if(!supabase||!productId)return [];
  const {data,error}=await supabase.from('product_images').select('id,product_id,url,sort_order').eq('product_id',productId).order('sort_order',{ascending:true});
  if(error){console.warn('Product gallery load skipped:',error.message);return [];}
  return data||[];
}
export async function getProductReviews(productId){
  if(!supabase||!productId)return [];
  const {data,error}=await supabase.from('reviews').select('id,product_id,customer_name,rating,review_text,photo_url,created_at').eq('product_id',productId).eq('approved',true).order('created_at',{ascending:false}).limit(100);
  if(error)throw error;
  return data||[];
}
export async function submitReview({productId,customerName,rating,reviewText,photoUrl=null}){
  if(!supabase)throw new Error('Supabase is not configured.');
  // Do not chain .select() here. New customer reviews are intentionally
  // inserted with approved=false, while public SELECT is restricted to
  // approved reviews. A post-insert SELECT therefore triggers an RLS error
  // even though the INSERT itself is valid.
  const {error}=await supabase.from('reviews').insert({
    product_id:productId,
    customer_name:String(customerName||'').trim().slice(0,80),
    rating:Number(rating),
    review_text:String(reviewText||'').trim().slice(0,1000),
    photo_url:photoUrl||null,
    approved:false
  });
  if(error)throw error;
  return {success:true};
}
async function reviewPhotoFallbackDataUrl(file){
  // Some deployments/environments can reach the Supabase database API but cannot
  // reach the Storage upload endpoint (often shown in browsers only as
  // "Failed to fetch"). Compress the customer photo in-browser and keep a
  // small self-contained copy in reviews.photo_url so the review is not lost.
  const dataUrl=await new Promise((resolve,reject)=>{
    const reader=new FileReader();
    reader.onload=()=>resolve(String(reader.result||''));
    reader.onerror=()=>reject(new Error('ছবিটি পড়া যাচ্ছে না। অন্য একটি ছবি চেষ্টা করুন।'));
    reader.readAsDataURL(file);
  });
  const compressed=await new Promise((resolve,reject)=>{
    const img=new Image();
    img.onload=()=>{
      const max=1000;
      const scale=Math.min(1,max/Math.max(img.naturalWidth||1,img.naturalHeight||1));
      const canvas=document.createElement('canvas');
      canvas.width=Math.max(1,Math.round((img.naturalWidth||1)*scale));
      canvas.height=Math.max(1,Math.round((img.naturalHeight||1)*scale));
      const ctx=canvas.getContext('2d');
      if(!ctx)return reject(new Error('ছবি process করা যাচ্ছে না।'));
      ctx.drawImage(img,0,0,canvas.width,canvas.height);
      const out=canvas.toDataURL('image/jpeg',0.72);
      // Keep DB payload reasonable. If the first encode is still large, reduce it again.
      if(out.length>1100000){
        const out2=canvas.toDataURL('image/jpeg',0.55);
        return resolve(out2.length<out.length?out2:out);
      }
      resolve(out);
    };
    img.onerror=()=>reject(new Error('ছবিটি process করা যাচ্ছে না।'));
    img.src=dataUrl;
  });
  return compressed;
}

export async function uploadReviewPhoto(file,productId){
  if(!supabase)throw new Error('Supabase is not configured.');
  if(!file)throw new Error('Please choose a photo.');
  const allowed=['image/jpeg','image/png','image/webp'];
  if(!allowed.includes(file.type))throw new Error('শুধু JPG, PNG বা WebP ছবি দেওয়া যাবে।');
  if(file.size>5*1024*1024)throw new Error('ছবির সাইজ সর্বোচ্চ 5MB হতে হবে।');
  const ext=(file.type.split('/')[1]||'jpg').replace('jpeg','jpg');
  const path=`reviews/${productId}/${Date.now()}-${Math.random().toString(36).slice(2,10)}.${ext}`;
  const bucket=supabase.storage.from('review-media');
  try{
    const {error}=await bucket.upload(path,file,{upsert:false,cacheControl:'31536000',contentType:file.type});
    if(!error){
      const {data}=bucket.getPublicUrl(path);
      if(data?.publicUrl)return data.publicUrl;
    }
  }catch(_e){
    // Fall through to the database-safe compressed-photo fallback below.
  }
  try{
    return await reviewPhotoFallbackDataUrl(file);
  }catch(e){
    throw new Error(e?.message||'ছবি upload করা যায়নি।');
  }
}
export async function validateCoupon(code,subtotal){
  if(!supabase)throw new Error('Supabase is not configured.');
  const clean=String(code||'').trim().toUpperCase();
  if(!clean)return {valid:false,discount:0,message:'কুপন কোড লিখুন।'};
  const {data,error}=await supabase.rpc('validate_coupon',{p_code:clean,p_subtotal:Number(subtotal)||0});
  if(error)throw error;
  return data||{valid:false,discount:0,message:'কুপন যাচাই করা যায়নি।'};
}
export async function getBanners(){if(!supabase)return[];const now=new Date().toISOString();const {data,error}=await supabase.from('banners').select('*').eq('active',true).or(`start_at.is.null,start_at.lte.${now}`).or(`end_at.is.null,end_at.gte.${now}`).order('sort_order');if(error)throw error;return data||[]}
export async function getPage(slug){if(!supabase)return null;const {data,error}=await supabase.from('pages').select('*').eq('slug',slug).eq('active',true).maybeSingle();if(error)throw error;return data}
export async function placeOrder(payload){if(!supabase)throw new Error('Supabase is not configured.');const {data,error}=await supabase.rpc('create_order_secure',{p_customer_name:payload.name,p_phone:payload.phone,p_division:payload.division,p_district:payload.district,p_area:payload.area,p_address:payload.address,p_note:payload.note||null,p_items:payload.items,p_coupon:payload.coupon?.trim()||null,p_delivery_area:payload.deliveryArea,p_payment_method:payload.paymentMethod||'Cash on Delivery'});if(error)throw error;return data}
export async function trackOrder(orderId,phone){if(!supabase)throw new Error('Supabase is not configured.');const {data,error}=await supabase.rpc('track_order',{p_order_id:orderId.trim(),p_phone:phone.trim()});if(error)throw error;return data?.[0]||null}
