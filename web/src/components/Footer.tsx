import './Footer.css'
import { useI18n, tr } from '../i18n'

function Footer() {
    const { lang, t } = useI18n()
    const year = new Date().getFullYear()

    return (
        <footer className="footer">
            <div className="footer-inner container">
                <div className="footer-top">
                    <div className="footer-brand">
                        <span className="footer-logo">Yisi</span>
                        <p className="footer-tagline">
                            {tr(t.footer.tagline, lang)}
                        </p>
                    </div>
                    <div className="footer-links">
                        <div className="footer-col">
                            <h4 className="footer-col-title">
                                {tr(t.footer.product, lang)}
                            </h4>
                            <a href="#features" className="footer-link">
                                {tr(t.footer.features, lang)}
                            </a>
                            <a href="#beyond" className="footer-link">
                                {tr(t.footer.beyond, lang)}
                            </a>
                            <a href="#why-yisi" className="footer-link">
                                {tr(t.footer.whyYisi, lang)}
                            </a>
                        </div>
                        <div className="footer-col">
                            <h4 className="footer-col-title">
                                {tr(t.footer.resources, lang)}
                            </h4>
                            <a
                                href="https://github.com/MUTRO888/Yisi"
                                className="footer-link"
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                GitHub
                            </a>
                            <a
                                href="https://github.com/MUTRO888/Yisi/releases"
                                className="footer-link"
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                {tr(t.footer.releases, lang)}
                            </a>
                            <a
                                href="https://github.com/MUTRO888/Yisi/issues"
                                className="footer-link"
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                {tr(t.footer.issues, lang)}
                            </a>
                        </div>
                    </div>
                </div>
                <div className="footer-bottom">
                    <p className="footer-copyright">
                        &copy; {year} Sonian Mu
                    </p>
                    <p className="footer-license">
                        {tr(t.footer.license, lang)}
                    </p>
                </div>
            </div>
        </footer>
    )
}

export default Footer
