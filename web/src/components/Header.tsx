import './Header.css'
import { useI18n, tr } from '../i18n'

function Header() {
    const { lang, toggle, t } = useI18n()

    return (
        <header className="header">
            <div className="header-inner container">
                <a href="/" className="header-logo">Yisi</a>
                <nav className="header-nav">
                    <a href="#features" className="header-link">
                        {tr(t.header.features, lang)}
                    </a>
                    <a href="#workflow" className="header-link">
                        {tr(t.header.workflow, lang)}
                    </a>
                    <a href="#demo" className="header-link">
                        {tr(t.header.demo, lang)}
                    </a>
                    <a
                        href="https://github.com/MUTRO888/Yisi"
                        className="header-link"
                        target="_blank"
                        rel="noopener noreferrer"
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
                </nav>
            </div>
        </header>
    )
}

export default Header
