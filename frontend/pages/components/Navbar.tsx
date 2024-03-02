import { HStack, Heading } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Image from 'next/image';
import logo from '../../public/img/eulSynth.svg'

const Navbar = () => {
  return (
    <div className='w-full px-10 py-6 flex justify-between'>
      <HStack>
        <Image src={logo} alt="logo" width={40} height={40} />
        <Heading as='h1' size='xl' fontWeight={300} lineHeight={1}>
          eulSynth
        </Heading>
      </HStack>
      <ConnectButton />
    </div>
  )
}

export default Navbar