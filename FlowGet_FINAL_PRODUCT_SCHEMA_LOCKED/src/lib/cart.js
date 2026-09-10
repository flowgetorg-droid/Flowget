const KEY='flowget_cart_v1';
const EVENT='flowget-cart-updated';
export const getCart=()=>{try{return JSON.parse(localStorage.getItem(KEY)||'[]')}catch{return[]}};
export const saveCart=(items)=>{localStorage.setItem(KEY,JSON.stringify(items));window.dispatchEvent(new CustomEvent(EVENT,{detail:items}));return items};
export const addCart=(p,q=1)=>{const c=getCart(),i=c.findIndex(x=>x.id===p.id);if(i>-1)c[i]={...c[i],...p,qty:c[i].qty+q};else c.push({...p,qty:q});return saveCart(c)};
export const removeCart=id=>saveCart(getCart().filter(x=>x.id!==id));
export const updateQty=(id,qty)=>saveCart(getCart().map(x=>x.id===id?{...x,qty:Math.max(0,Number(qty)||0)}:x).filter(x=>x.qty>0));
export const clearCart=()=>saveCart([]);
export const cartEvent=EVENT;
