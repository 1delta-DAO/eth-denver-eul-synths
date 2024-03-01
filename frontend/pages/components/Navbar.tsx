import { Heading } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';

const Navbar = () => {
  return (
    <div className='w-full px-10 py-6 flex justify-between'>
      <div>
        <Heading as='h1' size='xl' fontWeight={300}>
          eSynths
        </Heading>
      </div>
      <ConnectButton />
    </div>
  )
}

export default Navbar