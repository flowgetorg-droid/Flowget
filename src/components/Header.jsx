import React,{useEffect,useState} from 'react';
import {Link,useNavigate} from './Layout';
import {Search,ShoppingCart,Menu,X,User} from 'lucide-react';
import {getCart,cartEvent} from '../lib/cart';
export default function Header({settings}){
 const [open,setOpen]=useState(false),[q,setQ]=useState(''),[count,setCount]=useState(()=>getCart().reduce((s,x)=>s+Number(x.qty||0),0));
 const nav=useNavigate();
 useEffect(()=>{const sync=()=>setCount(getCart().reduce((s,x)=>s+Number(x.qty||0),0));window.addEventListener(cartEvent,sync);window.addEventListener('storage',sync);return()=>{window.removeEventListener(cartEvent,sync);window.removeEventListener('storage',sync)}},[]);
 const go=e=>{e.preventDefault();if(q.trim())nav('/search?q='+encodeURIComponent(q.trim()));setOpen(false)};
 return <><div className="announce">{settings.tagline||'Smart shopping for Bangladesh'}</div><header><div className="head"><button aria-label="Menu" className="icon mobile" onClick={()=>setOpen(!open)}>{open?<X/>:<Menu/>}</button><Link to="/" className="logo">{settings.logo_url?<img src={settings.logo_url} alt={settings.store_name}/>:<><span>F</span>{settings.store_name}</>}</Link><form className="search" onSubmit={go}><input aria-label="Search products" value={q} onChange={e=>setQ(e.target.value)} placeholder={settings.search_placeholder||'Search products...'}/><button aria-label="Search"><Search size={20}/></button></form><nav className={open?'open':''}><Link to="/">Home</Link><Link to="/shop">Shop</Link><Link to="/track-order">Track Order</Link><Link to="/about">About</Link><Link to="/contact">Contact</Link></nav><Link to="/my-orders" className="account"><User size={20}/><span>Orders</span></Link><Link to="/cart" className="cart" aria-label={`Cart with ${count} items`}><ShoppingCart size={21}/><b>{count}</b></Link></div></header></>;
}
