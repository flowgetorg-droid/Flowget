import React from 'react';
import { Link } from './Layout';
import { Mail, MessageCircle } from 'lucide-react';

const WHATSAPP = '8801822024595';
const EMAIL = 'flowget.org@gmail.com';

export default function Footer({ settings }) {
  return (
    <>
      <footer>
        <div className="footergrid">
          <div>
            <div className="logo footerlogo"><span>F</span>{settings.store_name}</div>
            <p>{settings.footer_about || 'মানসম্মত পণ্য, নির্ভরযোগ্য সেবা এবং সারা বাংলাদেশে সহজ অনলাইন শপিং।'}</p>
          </div>
          <div>
            <h4>কেনাকাটা</h4>
            <Link to="/shop">সব পণ্য</Link>
            <Link to="/shop?sort=newest">নতুন পণ্য</Link>
            <Link to="/shop?sort=popular">জনপ্রিয়</Link>
          </div>
          <div>
            <h4>কাস্টমার কেয়ার</h4>
            <Link to="/track-order">অর্ডার ট্র্যাক</Link>
            <Link to="/about">আমাদের সম্পর্কে</Link>
            <Link to="/faq">FAQ</Link>
            <Link to="/return-refund-policy">রিটার্ন ও রিফান্ড</Link>
            <Link to="/delivery-information">ডেলিভারি</Link>
          </div>
          <div>
            <h4>যোগাযোগ</h4>
            <a className="contactlink" href={`https://wa.me/${WHATSAPP}`} target="_blank" rel="noopener noreferrer">
              <MessageCircle size={16} /> হোয়াটসঅ্যাপ
            </a>
            <a className="contactlink" href={`mailto:${EMAIL}`}>
              <Mail size={16} /> {EMAIL}
            </a>
            <a className="contactlink" href={`https://wa.me/${WHATSAPP}`} target="_blank" rel="noopener noreferrer">
              +880 1822-024595
            </a>
          </div>
          <div>
            <h4>নীতিমালা</h4>
            <Link to="/privacy-policy">প্রাইভেসি পলিসি</Link>
            <Link to="/terms-conditions">শর্তাবলি</Link>
            <Link to="/contact">যোগাযোগ</Link>
          </div>
        </div>
        <div className="copyright">© {new Date().getFullYear()} {settings.store_name}. সর্বস্বত্ব সংরক্ষিত</div>
      </footer>
      <a
        className="whatsappFloat"
        href={`https://wa.me/${WHATSAPP}`}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Chat with FlowGet on হোয়াটসঅ্যাপ"
        title="Chat on হোয়াটসঅ্যাপ"
      >
        <MessageCircle size={24} />
        <span>হোয়াটসঅ্যাপ</span>
      </a>
    </>
  );
}
