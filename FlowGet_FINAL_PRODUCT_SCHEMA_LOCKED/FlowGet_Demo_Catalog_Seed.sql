-- FlowGet: realistic demo catalog seed
-- Adds useful Bangladesh e-commerce categories and 10 ready-to-sell sample products.
-- Safe to run more than once: categories/products are upserted by slug.

insert into public.categories (name, slug, icon, description, sort_order, active) values
('Electronics','electronics','⚡','Smart gadgets and everyday electronics.',1,true),
('Mobile Accessories','mobile-accessories','📱','Chargers, earbuds, cables and phone accessories.',2,true),
('Fashion','fashion','👕','Everyday clothing and lifestyle fashion.',3,true),
('Home & Kitchen','home-kitchen','🏠','Useful products for home and kitchen.',4,true),
('Beauty & Personal Care','beauty-personal-care','✨','Everyday personal care and grooming products.',5,true),
('Travel & Lifestyle','travel-lifestyle','🎒','Practical products for travel and daily life.',6,true)
on conflict (slug) do update set
  name=excluded.name, icon=excluded.icon, description=excluded.description,
  sort_order=excluded.sort_order, active=true;

with c as (select id,slug from public.categories)
insert into public.products
(name,slug,description,specifications,category_id,brand,sku,price,discount_price,stock,main_image,rating,review_count,featured,new_arrival,flash_deal,is_best_selling,active,seo_title,meta_description)
values
(
'FlowGet AirBeat Pro Wireless Earbuds','airbeat-pro-wireless-earbuds',
'Clear stereo sound with a compact charging case. Designed for calls, music and everyday commuting.',
'{"Color":"Black","Battery":"Up to 24 hours with case","Connection":"Bluetooth 5.3","Charging":"USB-C","Warranty":"7 days replacement"}'::jsonb,(select id from c where slug='mobile-accessories'),'FlowGet','FG-EB-PRO-001',1490,1190,25,
'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=1200&q=85',4.6,38,true,true,true,true,true,
'AirBeat Pro Wireless Earbuds | FlowGet','Wireless earbuds with Bluetooth 5.3, USB-C charging and up to 24 hours battery life.'
),(
'FlowGet Smart Watch X1','smart-watch-x1',
'Slim everyday smartwatch with a bright display, activity tracking and multiple watch faces.',
'{"Color":"Black","Display":"1.69 inch HD","Battery":"5-7 days typical use","Water Resistance":"IP67","Compatibility":"Android & iOS"}'::jsonb,(select id from c where slug='electronics'),'FlowGet','FG-SW-X1-002',2490,1990,18,
'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=1200&q=85',4.5,26,true,true,false,true,true,
'Smart Watch X1 | FlowGet','Affordable everyday smartwatch with HD display, activity tracking and long battery life.'
),(
'FlowGet SoundMax Wireless Headphones','soundmax-wireless-headphones',
'Comfortable over-ear wireless headphones for music, videos and work calls.',
'{"Color":"Black","Driver":"40mm","Connection":"Bluetooth 5.0","Battery":"Up to 20 hours","Charging":"USB-C"}'::jsonb,(select id from c where slug='electronics'),'FlowGet','FG-HP-SMAX-003',2290,1790,16,
'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=1200&q=85',4.4,19,false,true,true,false,true,
'SoundMax Wireless Headphones | FlowGet','Comfortable Bluetooth over-ear headphones for music, videos and calls.'
),(
'FlowGet Runner Casual Sneakers','runner-casual-sneakers',
'Lightweight everyday sneakers with a cushioned sole for walking, casual wear and travel.',
'{"Color":"White / Grey","Upper":"Mesh and synthetic","Sole":"Rubber","Sizes":"39-44","Use":"Walking / Casual"}'::jsonb,(select id from c where slug='fashion'),'FlowGet','FG-SNK-RUN-004',1890,1590,22,
'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200&q=85',4.7,41,true,false,false,true,true,
'Runner Casual Sneakers | FlowGet','Lightweight casual sneakers with cushioned rubber sole, available in sizes 39 to 44.'
),(
'FlowGet Classic Analog Watch','classic-analog-watch',
'Clean minimal analog watch with a simple dial for office, casual and everyday styling.',
'{"Color":"Black / Silver","Case":"Stainless steel look","Strap":"Faux leather","Dial":"Analog","Style":"Minimal"}'::jsonb,(select id from c where slug='fashion'),'FlowGet','FG-WT-CLS-005',1690,1390,14,
'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=1200&q=85',4.3,17,false,true,false,false,true,
'Classic Analog Watch | FlowGet','Minimal analog wristwatch with a clean dial and comfortable faux-leather strap.'
),(
'FlowGet Portable Blender Bottle','portable-blender-bottle',
'Compact rechargeable blender bottle for smoothies, shakes and quick drinks at home or office.',
'{"Color":"White","Capacity":"380ml","Charging":"USB rechargeable","Blade":"Stainless steel","Use":"Smoothies / Shakes"}'::jsonb,(select id from c where slug='home-kitchen'),'FlowGet','FG-KT-BLD-006',1790,1490,12,
'https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=1200&q=85',4.2,14,false,true,true,false,true,
'Portable Blender Bottle | FlowGet','Compact rechargeable blender for smoothies and shakes, ideal for home and office.'
),(
'FlowGet Aroma Mist Humidifier','aroma-mist-humidifier',
'Compact aroma diffuser and humidifier with soft ambient light for bedrooms and workspaces.',
'{"Color":"White","Capacity":"300ml","Power":"USB","Mist Modes":"Continuous / Intermittent","Use":"Bedroom / Office"}'::jsonb,(select id from c where slug='home-kitchen'),'FlowGet','FG-HM-MIST-007',1290,990,20,
'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=1200&q=85',4.5,22,false,true,false,true,true,
'Aroma Mist Humidifier | FlowGet','Compact USB aroma mist humidifier with ambient light for bedrooms and offices.'
),(
'FlowGet Grooming Trimmer T9','grooming-trimmer-t9',
'Rechargeable grooming trimmer with adjustable cutting settings for beard and personal care.',
'{"Color":"Black","Battery":"Up to 90 minutes","Charging":"USB","Settings":"Adjustable","Use":"Beard / Grooming"}'::jsonb,(select id from c where slug='beauty-personal-care'),'FlowGet','FG-BT-TRM-008',1390,1090,24,
'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=1200&q=85',4.4,29,false,true,true,true,true,
'Grooming Trimmer T9 | FlowGet','Rechargeable USB grooming trimmer with adjustable settings and up to 90 minutes battery.'
),(
'FlowGet Daily Backpack 20L','daily-backpack-20l',
'Practical 20L backpack with multiple compartments for office, study and short trips.',
'{"Color":"Black","Capacity":"20L","Material":"Water-resistant fabric","Compartments":"3 main sections","Use":"Office / Travel"}'::jsonb,(select id from c where slug='travel-lifestyle'),'FlowGet','FG-BAG-20L-009',1590,1290,30,
'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=1200&q=85',4.6,33,true,false,false,true,true,
'Daily Backpack 20L | FlowGet','20L water-resistant everyday backpack with multiple compartments for office and travel.'
),(
'FlowGet 20W Fast Charger','20w-fast-charger',
'Compact USB-C fast wall charger for compatible smartphones and everyday devices.',
'{"Color":"White","Output":"20W","Port":"USB-C","Input":"100-240V","Safety":"Over-current / Over-voltage protection"}'::jsonb,(select id from c where slug='mobile-accessories'),'FlowGet','FG-CH-20W-010',990,790,35,
'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=1200&q=85',4.5,45,false,true,true,true,true,
'20W Fast Charger | FlowGet','Compact 20W USB-C fast charger for compatible smartphones and everyday devices.'
)
on conflict (slug) do update set
 name=excluded.name,
 description=excluded.description,
 specifications=excluded.specifications,
 category_id=excluded.category_id,
 brand=excluded.brand,
 sku=excluded.sku,
 price=excluded.price,
 discount_price=excluded.discount_price,
 stock=excluded.stock,
 main_image=excluded.main_image,
 rating=excluded.rating,
 review_count=excluded.review_count,
 featured=excluded.featured,
 new_arrival=excluded.new_arrival,
 flash_deal=excluded.flash_deal,
 is_best_selling=excluded.is_best_selling,
 active=true,
 seo_title=excluded.seo_title,
 meta_description=excluded.meta_description;

-- Keep the seeded products' galleries in sync with their main images.
delete from public.product_images pi
where pi.product_id in (select id from public.products where slug in (
'airbeat-pro-wireless-earbuds','smart-watch-x1','soundmax-wireless-headphones','runner-casual-sneakers','classic-analog-watch','portable-blender-bottle','aroma-mist-humidifier','grooming-trimmer-t9','daily-backpack-20l','20w-fast-charger'));

insert into public.product_images(product_id,url,sort_order)
select p.id,p.main_image,10 from public.products p
where p.slug in ('airbeat-pro-wireless-earbuds','smart-watch-x1','soundmax-wireless-headphones','runner-casual-sneakers','classic-analog-watch','portable-blender-bottle','aroma-mist-humidifier','grooming-trimmer-t9','daily-backpack-20l','20w-fast-charger');

-- Add a second image to each seeded product using a stable Unsplash image where available.
with imgs(slug,url) as (values
('airbeat-pro-wireless-earbuds','https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=1200&q=85'),
('smart-watch-x1','https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=1200&q=85'),
('soundmax-wireless-headphones','https://images.unsplash.com/photo-1484704849700-f032a568e944?w=1200&q=85'),
('runner-casual-sneakers','https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200&q=85'),
('classic-analog-watch','https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=1200&q=85'),
('portable-blender-bottle','https://images.unsplash.com/photo-1616091216791-a5360b5fc78a?w=1200&q=85'),
('aroma-mist-humidifier','https://images.unsplash.com/photo-1603006905003-be475563bc59?w=1200&q=85'),
('grooming-trimmer-t9','https://images.unsplash.com/photo-1621607512214-68297480165e?w=1200&q=85'),
('daily-backpack-20l','https://images.unsplash.com/photo-1581605405669-fcdf81165afa?w=1200&q=85'),
('20w-fast-charger','https://images.unsplash.com/photo-1609592424830-4fbdc0e9fca5?w=1200&q=85')
)
insert into public.product_images(product_id,url,sort_order)
select p.id,i.url,20 from imgs i join public.products p on p.slug=i.slug;

notify pgrst, 'reload schema';
