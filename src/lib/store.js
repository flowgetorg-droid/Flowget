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
    if(p.active!==undefined&&p.active!==true)return false;
    const a=String(p.slug||'').toLowerCase().replace(/[^a-z0-9]/g,'');
    const b=String(p.sku||'').toLowerCase().replace(/[^a-z0-9]/g,'');
    return a===key||b===key;
  })||null;
  return product?{...product,product_images:[]}:null;
}
export async function getProductImages(productId){
  if(!supabase||!productId)return [];
  const {data,error}=await supabase.from('product_images').select('id,product_id,url,sort_order').eq('product_id',productId).order('sort_order',{ascending:true});
  if(error){console.warn('Product gallery load skipped:',error.message);return [];}
  return data||[];
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
