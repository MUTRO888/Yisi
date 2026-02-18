import { useState } from 'react'
import './Hero.css'
import Particles from './Particles'
import HarmonicFlow from './HarmonicFlow'

type HeroState = 'english' | 'processing' | 'chinese' | 'fully-revealed'

function Hero() {
    const [heroState, setHeroState] = useState<HeroState>('english')
    const [isHovering, setIsHovering] = useState(false)

    const handleInteraction = () => {
        if (heroState === 'english') {
            setHeroState('processing')
        }
    }

    const handleFlowComplete = () => {
        setHeroState('chinese')
        // Small delay before showing the final brand elements
        setTimeout(() => setHeroState('fully-revealed'), 800)
    }

    const englishText = `The sound of the spring sobs among the perilous stones;\nthe color of the sun chills the green pines.`

    return (
        <section className="hero section">
            <Particles />

            <div className={`hero-content ${heroState}`}>

                {/* State 1: English Text (Interactive) */}
                {heroState === 'english' && (
                    <div
                        className="text-interaction-zone"
                        onMouseEnter={() => setIsHovering(true)}
                        onMouseLeave={() => setIsHovering(false)}
                        onClick={handleInteraction}
                    >
                        <p className={`poetic-text source ${isHovering ? 'hovered' : ''}`}>
                            The sound of the spring sobs among the perilous stones;<br />
                            the color of the sun chills the green pines.
                        </p>
                        <div className={`interaction-hint ${isHovering ? 'visible' : ''}`}>
                            <span>Click to translate like flowing water</span>
                        </div>
                    </div>
                )}

                {/* State 2: Harmonic Flow (Processing) */}
                {heroState === 'processing' && (
                    <div className="flow-container">
                        <HarmonicFlow
                            text={englishText}
                            duration={2200}
                            onComplete={handleFlowComplete}
                        />
                    </div>
                )}

                {/* State 3: Chinese Text (Result) & Footer */}
                {(heroState === 'chinese' || heroState === 'fully-revealed') && (
                    <div className="result-container">
                        <p className="poetic-text target">
                            泉声咽危石，<br />
                            日色冷青松。
                        </p>

                        <div className={`hero-footer ${heroState === 'fully-revealed' ? 'visible' : ''}`}>
                            <h1 className="brand-title">Yisi</h1>
                            <p className="brand-subtitle">Everything gains meaning in translation.</p>
                            <div className="hero-actions">
                                <a
                                    href="https://github.com/MUTRO888/Yisi/releases"
                                    className="btn btn-primary"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                >
                                    Download
                                </a>
                            </div>
                        </div>
                    </div>
                )}

            </div>
        </section>
    )
}

export default Hero
