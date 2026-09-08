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
            <p>{settings.footer_about || 'Smart products, reliable service and easy shopping for customers across Bangladesh.'}</p>
          </div>
          <div>
            <h4>Shop</h4>
            <Link to="/shop">All Products</Link>
            <Link to="/shop?sort=newest">New Arrivals</Link>
            <Link to="/shop?sort=popular">Popular</Link>
          </div>
          <div>
            <h4>Customer Care</h4>
            <Link to="/track-order">Track Order</Link>
            <Link to="/about">About Us</Link>
            <Link to="/faq">FAQ</Link>
            <Link to="/return-refund-policy">Returns & Refunds</Link>
            <Link to="/delivery-information">Delivery</Link>
          </div>
          <div>
            <h4>Contact</h4>
            <a className="contactlink" href={`https://wa.me/${WHATSAPP}`} target="_blank" rel="noopener noreferrer">
              <MessageCircle size={16} /> WhatsApp
            </a>
            <a className="contactlink" href={`mailto:${EMAIL}`}>
              <Mail size={16} /> {EMAIL}
            </a>
            <a className="contactlink" href={`https://wa.me/${WHATSAPP}`} target="_blank" rel="noopener noreferrer">
              +880 1822-024595
            </a>
          </div>
          <div>
            <h4>Legal</h4>
            <Link to="/privacy-policy">Privacy Policy</Link>
            <Link to="/terms-conditions">Terms & Conditions</Link>
            <Link to="/contact">Contact</Link>
          </div>
        </div>
        <div className="copyright">© {new Date().getFullYear()} {settings.store_name}. All rights reserved.</div>
      </footer>
      <a
        className="whatsappFloat"
        href={`https://wa.me/${WHATSAPP}`}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Chat with FlowGet on WhatsApp"
        title="Chat on WhatsApp"
      >
        <MessageCircle size={24} />
        <span>WhatsApp</span>
      </a>
    </>
  );
}
