import Header from './components/Header'
import Hero from './components/Hero'
import DownloadCTA from './components/DownloadCTA'
import Features from './components/Features'
import Beyond from './components/Workflow'
import WhyYisi from './components/AppDemo'
import Principles from './components/Principles'
import BottomCTA from './components/BottomCTA'
import Footer from './components/Footer'

function App() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <DownloadCTA />
        <Features />
        <Beyond />
        <WhyYisi />
        <Principles />
        <BottomCTA />
      </main>
      <Footer />
    </>
  )
}

export default App
