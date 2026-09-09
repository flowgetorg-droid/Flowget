import {supabase} from './supabase';
export const fallbackSettings={store_name:'FlowGet',tagline:'Smart products. Simple shopping.',phone:'',email:'',primary:'#f97316',primary_hover:'#ea580c',secondary:'#111827',delivery_dhaka:80,delivery_outside:140,currency:'৳'};
export async function getSettings(){if(!supabase)return fallbackSettings;const {data,error}=await supabase.from('website_settings').select('*').eq('id',true).maybeSingle();if(error)throw error;return data?{...fallbackSettings,...data}:fallbackSettings}
export async function getCategories(){if(!supabase)return[];const {data,error}=await supabase.from('categories').select('*').eq('active',true).order('sort_order');if(error)throw error;return data||[]}
export async function getProducts({category,search,sort='newest',minPrice,maxPrice,brand,available}={}){
  if(!supabase)return[];
  let q=supabase.from('products').select('*').eq('active',true);
  if(category)q=q.eq('category_id',category);
  if(search){const safe=search.replace(/[%_,()]/g,' ');q=q.or(`name.ilike.%${safe}%,sku.ilike.%${safe}%,brand.ilike.%${safe}%`)}
  if(brand)q=q.eq('brand',brand);
  if(minPrice!==undefined&&minPrice!=='')q=q.gte('discount_price',Number(minPrice));
  if(maxPrice!==undefined&&maxPrice!=='')q=q.lte('discount_price',Number(maxPrice));
  if(available)q=q.gt('stock',0);
  if(sort==='price_asc')q=q.order('discount_price',{ascending:true,nullsFirst:false});
  else if(sort==='price_desc')q=q.order('discount_price',{ascending:false,nullsFirst:false});
  else if(sort==='popular')q=q.order('review_count',{ascending:false});
  else q=q.order('created_at',{ascending:false});
  const {data,error}=await q;
  if(error)throw error;
  const products=data||[];
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
  const raw=decodeURIComponent(String(slug||'')).trim();
  if(!raw)return null;
  const clean=raw.split('?')[0].split('#')[0].trim();
  let {data,error}=await supabase.from('products').select('*').eq('slug',clean).eq('active',true).maybeSingle();
  if(error)throw error;
  if(!data){
    const key=clean.toLowerCase().replace(/[^a-z0-9]/g,'');
    const {data:candidates,error:candidateError}=await supabase.from('products').select('*').eq('active',true).limit(2000);
    if(candidateError)throw candidateError;
    data=(candidates||[]).find(p=>{
      const a=String(p.slug||'').toLowerCase().replace(/[^a-z0-9]/g,'');
      const b=String(p.sku||'').toLowerCase().replace(/[^a-z0-9]/g,'');
      return a===key||b===key;
    })||null;
  }
  if(!data)return null;
  const {data:images,error:imageError}=await supabase.from('product_images').select('id,product_id,url,sort_order').eq('product_id',data.id).order('sort_order',{ascending:true});
  if(imageError){console.warn('Product gallery load skipped:',imageError.message);return {...data,product_images:[]};}
  return {...data,product_images:images||[]};
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
