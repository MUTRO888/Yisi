import Header from './components/Header'
import Hero from './components/Hero'
import Showcase from './components/Showcase'
import Features from './components/Features'
import Workflow from './components/Workflow'
import AppDemo from './components/AppDemo'
import Principles from './components/Principles'
import DownloadCTA from './components/DownloadCTA'
import Footer from './components/Footer'

function App() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Showcase />
        <Features />
        <Workflow />
        <AppDemo />
        <Principles />
        <DownloadCTA />
      </main>
      <Footer />
    </>
  )
}

export default App
