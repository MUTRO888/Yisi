import { useState, useEffect } from 'react'
import './Header.css'
import { useI18n, tr } from '../i18n'
import YisiAppIcon from './YisiAppIcon'

function Header() {
    const { lang, toggle, t } = useI18n()
    const [showDownload, setShowDownload] = useState(false)
    const [menuOpen, setMenuOpen] = useState(false)

    useEffect(() => {
        const heroActions = document.querySelector('.hero-actions')
        const bottomCta = document.querySelector('.bottom-cta')
        if (!heroActions && !bottomCta) return

        const visible = new Set<Element>()

        const observer = new IntersectionObserver(
            (entries) => {
                for (const entry of entries) {
                    if (entry.isIntersecting) {
                        visible.add(entry.target)
                    } else {
                        visible.delete(entry.target)
                    }
                }
                setShowDownload(visible.size === 0)
            },
            { threshold: 0 }
        )

        if (heroActions) observer.observe(heroActions)
        if (bottomCta) observer.observe(bottomCta)

        return () => observer.disconnect()
    }, [])

    useEffect(() => {
        if (!menuOpen) return
        const onResize = () => {
            if (window.innerWidth > 768) setMenuOpen(false)
        }
        window.addEventListener('resize', onResize)
        return () => window.removeEventListener('resize', onResize)
    }, [menuOpen])

    const closeMenu = () => setMenuOpen(false)

    return (
        <header className="header">
            <div className="header-inner">
                <a href="/" className="header-logo">
                    <YisiAppIcon size={28} />
                    <span className="header-logo-text">Yisi</span>
                </a>
                <button
                    className={`header-burger${menuOpen ? ' active' : ''}`}
                    onClick={() => setMenuOpen(!menuOpen)}
                    aria-label="Toggle menu"
                >
                    <span />
                    <span />
                    <span />
                </button>
                <nav className={`header-nav${menuOpen ? ' open' : ''}`}>
                    <a href="#features" className="header-link" onClick={closeMenu}>
                        {tr(t.header.features, lang)}
                    </a>
                    <a href="#beyond" className="header-link" onClick={closeMenu}>
                        {tr(t.header.beyond, lang)}
                    </a>
                    <a href="#why-yisi" className="header-link" onClick={closeMenu}>
                        {tr(t.header.whyYisi, lang)}
                    </a>
                    <a
                        href="https://github.com/MUTRO888/Yisi"
                        className="header-link"
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={closeMenu}
                    >
                        GitHub
                    </a>
                    <button
                        className="header-lang"
                        onClick={toggle}
                        aria-label="Switch language"
                    >
                        {lang === 'en' ? '中文' : 'EN'}
                    </button>
                    <a
                        href="https://github.com/MUTRO888/Yisi/releases"
                        className={`header-download${showDownload ? ' visible' : ''}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={closeMenu}
                    >
                        {tr(t.hero.download, lang)}
                    </a>
                </nav>
            </div>
        </header>
    )
}

export default Header
