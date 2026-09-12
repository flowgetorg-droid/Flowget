// FlowGet Bangladesh location picker
// Primary source: BDAPIs (8 divisions, 64 districts, upazilas).
// Fallback: nested Bangladesh geo JSON. Data is cached locally after a successful load.
const PRIMARY='https://bdapis.com/api/v1.2';
const FALLBACK_API='https://iqbalhasandev.github.io/bangladesh-geo-json/bangladesh-geo.json';
const CACHE='flowget-bd-geo-v5';

const fallbackDivisions=[
  {name:'Barishal',bn_name:'বরিশাল',districts:[]},{name:'Chattogram',bn_name:'চট্টগ্রাম',districts:[]},
  {name:'Dhaka',bn_name:'ঢাকা',districts:[]},{name:'Khulna',bn_name:'খুলনা',districts:[]},
  {name:'Mymensingh',bn_name:'ময়মনসিংহ',districts:[]},{name:'Rajshahi',bn_name:'রাজশাহী',districts:[]},
  {name:'Rangpur',bn_name:'রংপুর',districts:[]},{name:'Sylhet',bn_name:'সিলেট',districts:[]}
];



// Dhaka District / Dhaka Metropolitan Police (DMP) police stations.
// The Bangladesh National Portal lists 5 administrative upazilas for Dhaka District,
// while Bangladesh Police/DMP separately lists the metropolitan police stations.
// Checkout uses the combined list so customers in Dhaka city can select their actual thana.
const DHAKA_DMP_THANAS=[
  ['Adabor','আদাবর'],['Airport','এয়ারপোর্ট'],['Badda','বাড্ডা'],['Banani','বনানী'],['Bangshal','বংশাল'],
  ['Bhashantek','ভাষানটেক'],['Cantonment','ক্যান্টনমেন্ট'],['Chackbazar','চকবাজার'],['Dakshin Khan','দক্ষিণখান'],
  ['Darus-Salam','দারুস-সালাম'],['Demra','ডেমরা'],['Dhanmondi','ধানমন্ডি'],['Gandaria','গেন্ডারিয়া'],['Gulshan','গুলশান'],
  ['Hazaribag','হাজারীবাগ'],['Jatrabari','যাত্রাবাড়ী'],['Kadamtoli','কদমতলী'],['Kafrul','কাফরুল'],['Kalabagan','কলাবাগান'],
  ['Kamrangirchar','কামরাঙ্গীরচর'],['Khilgaon','খিলগাঁও'],['Khilkhet','খিলক্ষেত'],['Kotwali','কোতোয়ালি'],['Lalbag','লালবাগ'],
  ['Mirpur Model','মিরপুর মডেল'],['Mohammadpur','মোহাম্মদপুর'],['Motijheel','মতিঝিল'],['Mugda','মুগদা'],['New Market','নিউ মার্কেট'],
  ['Pallabi','পল্লবী'],['Paltan Model','পল্টন মডেল'],['Ramna Model','রমনা মডেল'],['Rampura','রামপুরা'],['Rupnagar','রূপনগর'],
  ['Sabujbag','সবুজবাগ'],['Shah Ali','শাহ আলী'],['Shahbag','শাহবাগ'],['Shahjahanpur','শাহজাহানপুর'],['Sher e Bangla Nagar','শেরেবাংলা নগর'],
  ['Shyampur','শ্যামপুর'],['Sutrapur','সূত্রাপুর'],['Tejgaon','তেজগাঁও'],['Tejgaon I/A','তেজগাঁও শিল্পাঞ্চল'],['Turag','তুরাগ'],
  ['Uttara Model','উত্তরা মডেল'],['Uttarkhan','উত্তরখান'],['Uttara West','উত্তরা পশ্চিম'],['Vatara','ভাটারা'],['Wari','ওয়ারী']
].map(([name,bn_name])=>({name,bn_name}));

function mergeDhakaThanas(divisions){
  const dhaka=divisions.find(x=>x.name.toLowerCase()==='dhaka' || x.bn_name==='ঢাকা');
  if(!dhaka)return divisions;
  const seen=new Set((dhaka.districts||[]).flatMap(d=>(d.upazilas||[]).map(u=>`${u.name}|${u.bn_name}`)));
  let district=dhaka.districts.find(d=>d.name.toLowerCase()==='dhaka' || d.bn_name==='ঢাকা');
  if(!district){
    district={name:'Dhaka',bn_name:'ঢাকা',upazilas:[]};
    dhaka.districts.push(district);
  }
  for(const t of DHAKA_DMP_THANAS){
    const key=`${t.name}|${t.bn_name}`;
    if(!seen.has(key))district.upazilas.push(t);
  }
  return divisions;
}

function valid(data){return Array.isArray(data)&&data.length===8&&data.every(x=>x&&typeof x.name==='string'&&typeof x.bn_name==='string'&&Array.isArray(x.districts)&&x.districts.every(d=>Array.isArray(d.upazilas)));}
const text=(o,...keys)=>{for(const k of keys){if(o&&o[k]!=null&&String(o[k]).trim())return String(o[k]).trim()}return ''};

async function json(url){const r=await fetch(url,{headers:{Accept:'application/json'},cache:'no-store',mode:'cors'});if(!r.ok)throw new Error(`HTTP ${r.status}`);const j=await r.json();return j?.data??j}

async function loadPrimary(){
  const [dv,ds,uz]=await Promise.all([json(`${PRIMARY}/divisions`),json(`${PRIMARY}/districts`),json(`${PRIMARY}/upazilas`)]);
  if(!Array.isArray(dv)||!Array.isArray(ds)||!Array.isArray(uz))throw new Error('Invalid location response');
  const divisions=dv.map(x=>({id:text(x,'id','division_id'),name:text(x,'division','name'),bn_name:text(x,'divisionbn','bn_name'),districts:[]})).filter(x=>x.name&&x.bn_name);
  const byDiv=new Map(divisions.map(x=>[x.name.toLowerCase(),x]));
  const districts=ds.map(x=>({id:text(x,'id','district_id'),name:text(x,'district','name'),bn_name:text(x,'districtbn','bn_name'),division:text(x,'division','division_name','divisionName'),divisionbn:text(x,'divisionbn','division_bn','divisionbn_name')})).filter(x=>x.name&&x.bn_name);
  const byDistrict=new Map();
  for(const d of districts){
    let parent=byDiv.get((d.division||'').toLowerCase());
    if(!parent&&d.divisionbn)parent=divisions.find(v=>v.bn_name===d.divisionbn);
    if(!parent)continue;
    const item={name:d.name,bn_name:d.bn_name,upazilas:[]};parent.districts.push(item);byDistrict.set(d.name.toLowerCase(),item);byDistrict.set(`${(parent.name||'').toLowerCase()}::${d.name.toLowerCase()}`,item);
  }
  for(const u of uz){
    const name=text(u,'upazila','name'),bn=text(u,'upazilabn','upazila_bn','bn_name');if(!name||!bn)continue;
    const dn=text(u,'district','district_name','districtName');const dbn=text(u,'districtbn','district_bn');const vn=text(u,'division','division_name','divisionName');
    let d=byDistrict.get(`${(vn||'').toLowerCase()}::${(dn||'').toLowerCase()}`)||byDistrict.get((dn||'').toLowerCase());
    if(!d&&dbn){for(const x of districts){if(x.bn_name===dbn){d=byDistrict.get(`${(x.division||'').toLowerCase()}::${x.name.toLowerCase()}`)||byDistrict.get(x.name.toLowerCase());break}}}
    if(d)d.upazilas.push({name,bn_name:bn});
  }
  if(!valid(divisions)||divisions.some(d=>!d.districts.length))throw new Error('Incomplete primary location data');
  return mergeDhakaThanas(divisions);
}

async function loadFallback(){const data=await json(FALLBACK_API);if(!valid(data))throw new Error('Invalid fallback location data');return data}

export async function getBangladeshLocations(){
  try{const cached=JSON.parse(localStorage.getItem(CACHE)||'null');if(valid(cached))return mergeDhakaThanas(cached)}catch{}
  try{const data=await loadPrimary();try{localStorage.setItem(CACHE,JSON.stringify(data))}catch{}return data}catch(primaryErr){
    try{const data=mergeDhakaThanas(await loadFallback());try{localStorage.setItem(CACHE,JSON.stringify(data))}catch{}return data}catch(fallbackErr){
      throw new Error('বাংলাদেশের বিভাগ, জেলা ও উপজেলা/থানা তালিকা লোড করা যায়নি।');
    }
  }
}

export function getLocationFallback(){return fallbackDivisions}
