import './Showcase.css'
import { useI18n, tr } from '../i18n'

function Showcase() {
    const { lang, t } = useI18n()

    return (
        <section className="showcase section">
            <div className="showcase-inner container">
                <h2 className="showcase-heading">
                    {tr(t.showcase.heading, lang)}
                </h2>
                <p className="showcase-sub">
                    {tr(t.showcase.sub, lang)}
                </p>
                <div className="showcase-frame">
                    <div className="showcase-placeholder">
                        <div className="showcase-window-bar">
                            <span className="showcase-dot" />
                            <span className="showcase-dot" />
                            <span className="showcase-dot" />
                        </div>
                        <div className="showcase-window-body">
                            <p className="showcase-placeholder-text">
                                {tr(t.showcase.placeholder, lang)}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    )
}

export default Showcase
