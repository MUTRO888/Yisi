import './DownloadCTA.css'
import { useI18n, tr } from '../i18n'

function DownloadCTA() {
    const { lang, t } = useI18n()

    return (
        <section className="download-cta section">
            <div className="download-cta-inner container">
                <h2 className="download-cta-heading">
                    {tr(t.downloadCTA.heading, lang)}
                </h2>
                <p className="download-cta-sub">
                    {tr(t.downloadCTA.sub, lang)}
                </p>
                <a
                    href="https://github.com/MUTRO888/Yisi/releases"
                    className="download-cta-btn"
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    {tr(t.downloadCTA.button, lang)}
                </a>
                <div className="download-cta-meta">
                    <span className="download-cta-req">
                        {tr(t.downloadCTA.requires, lang)}
                    </span>
                    <span className="download-cta-sep" aria-hidden="true" />
                    <a
                        href="https://github.com/MUTRO888/Yisi"
                        className="download-cta-source"
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        {tr(t.downloadCTA.source, lang)}
                    </a>
                </div>
            </div>
        </section>
    )
}

export default DownloadCTA
