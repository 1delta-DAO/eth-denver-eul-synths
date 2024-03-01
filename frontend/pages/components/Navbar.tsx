import { ConnectButton } from '@rainbow-me/rainbowkit';

const Navbar = () => {
  return (
    <div className='w-full p-5 flex justify-between'>
      <div>
        <h1 className='text-2xl font-bold'>eSynths</h1>
      </div>
      <ConnectButton />
    </div>
  )
}

export default Navbar