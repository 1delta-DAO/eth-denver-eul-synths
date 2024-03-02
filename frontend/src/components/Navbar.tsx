import { Avatar, HStack, Heading, Menu, MenuButton, MenuItem, MenuList, Text } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Image from 'next/image';
import logo from '../../public/img/eulSynths.svg'
import { symbolToAsset } from '../constants';
import { useFaucet } from '../hooks/useCallFaucet';

const Navbar = () => {

  const USDC = symbolToAsset.USDC
  const DAI = symbolToAsset.DAI

  const callFaucet = useFaucet()

  return (
    <div className='w-full px-10 py-6 flex justify-between'>
      <HStack>
        <Image src={logo} alt="logo" width={40} height={40} />
        <Heading as='h1' size='xl' fontWeight={300} lineHeight={1}>
          eulSynths
        </Heading>
      </HStack>
      <HStack gap="2em">
        <Menu>
          <MenuButton
            as={Text}
            minW="unset%"
            height="auto"
            padding="0.5em"
            fontWeight={400}
            fontSize="1.1em"
            _hover={{
              color: "#818181",
              cursor: "pointer",
            }}
            transition="all 0.2s ease-in-out"
          >
            Faucet
          </MenuButton>
          <MenuList zIndex={999} minW="0">
            <MenuItem
              onClick={() => callFaucet(USDC.symbol)}
              gap="0.5em"
            >
              <Avatar src={USDC.icon} name={USDC.name} size="2xs" />
              {USDC.symbol}
            </MenuItem>
            <MenuItem
              onClick={() => callFaucet(DAI.symbol)}
              gap="0.5em"
            >
              <Avatar src={DAI.icon} name={DAI.name} size="2xs" />
              {DAI.symbol}
            </MenuItem>
          </MenuList>
        </Menu>
        <ConnectButton />
      </HStack>
    </div>
  )
}

export default Navbar