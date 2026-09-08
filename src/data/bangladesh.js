const API='https://iqbalhasandev.github.io/bangladesh-geo-json/bangladesh-geo.json';
const CACHE='flowget-bd-geo-v1';

const fallback=[
 {name:'Dhaka',bn_name:'ঢাকা',districts:[]},
 {name:'Chattagram',bn_name:'চট্টগ্রাম',districts:[]},
 {name:'Rajshahi',bn_name:'রাজশাহী',districts:[]},
 {name:'Khulna',bn_name:'খুলনা',districts:[]},
 {name:'Barisal',bn_name:'বরিশাল',districts:[]},
 {name:'Sylhet',bn_name:'সিলেট',districts:[]},
 {name:'Rangpur',bn_name:'রংপুর',districts:[]},
 {name:'Mymensingh',bn_name:'ময়মনসিংহ',districts:[]}
];

export async function getBangladeshLocations(){
  try{
    const cached=localStorage.getItem(CACHE);
    if(cached){const parsed=JSON.parse(cached);if(Array.isArray(parsed)&&parsed.length)return parsed}
  }catch{}
  const r=await fetch(API,{headers:{Accept:'application/json'}});
  if(!r.ok)throw new Error('বাংলাদেশের ঠিকানার তালিকা লোড করা যায়নি।');
  const data=await r.json();
  if(!Array.isArray(data)||!data.length)throw new Error('বাংলাদেশের ঠিকানার তালিকা পাওয়া যায়নি।');
  try{localStorage.setItem(CACHE,JSON.stringify(data))}catch{}
  return data;
}

export function getLocationFallback(){return fallback}
