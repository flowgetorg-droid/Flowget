// FlowGet Bangladesh location picker
// Source: bilingual Bangladesh administrative hierarchy (8 divisions, 64 districts, 495 upazilas).
const API = 'https://iqbalhasandev.github.io/bangladesh-geo-json/bangladesh-geo.json';
const CACHE = 'flowget-bd-geo-v2';

const fallback = [
  {name:'Barishal',bn_name:'বরিশাল',districts:[]},
  {name:'Chattagram',bn_name:'চট্টগ্রাম',districts:[]},
  {name:'Dhaka',bn_name:'ঢাকা',districts:[]},
  {name:'Khulna',bn_name:'খুলনা',districts:[]},
  {name:'Mymensingh',bn_name:'ময়মনসিংহ',districts:[]},
  {name:'Rajshahi',bn_name:'রাজশাহী',districts:[]},
  {name:'Rangpur',bn_name:'রংপুর',districts:[]},
  {name:'Sylhet',bn_name:'সিলেট',districts:[]}
];

function valid(data){
  return Array.isArray(data) && data.length === 8 && data.every(x =>
    x && typeof x.name === 'string' && typeof x.bn_name === 'string' && Array.isArray(x.districts)
  );
}

export async function getBangladeshLocations(){
  // Never use an old/invalid cached hierarchy.
  try{
    const cached = localStorage.getItem(CACHE);
    if(cached){
      const parsed = JSON.parse(cached);
      if(valid(parsed)) return parsed;
      localStorage.removeItem(CACHE);
    }
  }catch{}

  const r = await fetch(API, {
    method:'GET',
    mode:'cors',
    cache:'no-store',
    headers:{Accept:'application/json'}
  });

  if(!r.ok) throw new Error('বাংলাদেশের ঠিকানার তালিকা লোড করা যায়নি।');

  const data = await r.json();
  if(!valid(data)) throw new Error('ঠিকানার তালিকার ফরম্যাট সঠিক নয়।');

  try{ localStorage.setItem(CACHE, JSON.stringify(data)); }catch{}
  return data;
}

export function getLocationFallback(){ return fallback; }
