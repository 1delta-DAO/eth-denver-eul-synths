import { Button } from "@chakra-ui/button"
import { Input } from "@chakra-ui/input"
import { HStack, Heading, VStack } from "@chakra-ui/layout"
import { Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/menu"
import { ChevronDownIcon } from "@chakra-ui/icons"
import LeverageSlider from "./Slider/LeverageSlider"
import { useState } from "react"
import { Accordion, AccordionButton, AccordionIcon, AccordionItem, AccordionPanel, Avatar, Box } from "@chakra-ui/react"
import { PoolAsset, payAssets } from "../src/constants"
import Image from "next/image"

const Manager = () => {

  const [leverage, setLeverage] = useState(1)
  const [inputValue, setInputValue] = useState<string>("")
  
  const maxLeverage = 10
  const outputValue = inputValue ? (Math.round((Number(inputValue) * leverage) * 10000) / 10000).toString() : "0"

  const [payAsset, setPayAsset] = useState<PoolAsset | null>(payAssets[0])

  return (
    <VStack gap="1em" w="100%" alignItems="flex-start">
      <Heading as='h2' size='lg' fontWeight={300}>
        Create Position
      </Heading>
      <VStack
        padding="0.5em"
        background="#dddddd"
        borderRadius="0.5em"
        w="100%"
        gap="0.5em"
      >
        <HStack
          w="100%"
          p="1em"
          borderRadius="0.5em"
          justifyContent="space-between"
          background="white"
        >
          <Input
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            border="none"
            _focusVisible={{
              outline: "none",
            }}
            w="50%"
            type="number"
            p="0"
            h="fit-content"
            fontSize="1.5em"
            placeholder="Insert Amount"
          />
          <Menu>
            <MenuButton
              as={Button}
              rightIcon={<ChevronDownIcon />}
              minW="35%"
              border="1px solid #dddddd"
              background="transparent"
              _hover={{
                background: "#dddddd",
              }}
              _active={{
                outline: "none",
                background: "#dddddd",
              }}
            >
              {
                payAsset ? (
                  <HStack w="100%">
                    <Avatar src={payAsset.icon} name={payAsset.name} size="2xs" />
                    <div>
                      {payAsset.symbol}
                    </div>
                  </HStack>
                ) : "Select Asset"
              }
            </MenuButton>
            <MenuList zIndex={999} minW="0">
              {
                payAssets.map((asset) => (
                  <MenuItem
                    key={asset.symbol}
                    onClick={() => setPayAsset(asset)}
                    gap="0.5em"
                  >
                    <Avatar src={asset.icon} name={asset.name} size="2xs" />
                    {asset.symbol}
                  </MenuItem>
                ))
              }
            </MenuList>
          </Menu>
        </HStack>
        <LeverageSlider
          value={leverage}
          maxLeverage={maxLeverage}
          tooltipSymbol={"x"}
          onChange={setLeverage}
        />
        <HStack
          w="100%"
          p="1em"
          borderRadius="0.5em"
          justifyContent="space-between"
          background="white"
        >
          <Box
            w="50%"
            h="fit-content"
            fontSize="1.5em"
          >
            {outputValue}
          </Box>
          <div>
            USD-3Pool
          </div>
        </HStack>
        <Accordion w="100%" allowToggle defaultIndex={[0]} background="white" border="none" borderRadius="0.5em">
          <AccordionItem border="none">
            <h2>
              <AccordionButton
                _hover={{
                  background: "transparent",
                }}
              >
                <Box as="span" flex='1' textAlign='left'>
                  Pool Info
                </Box>
                <AccordionIcon />
              </AccordionButton>
            </h2>
            <AccordionPanel pb={4}>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
              tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
              veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
              commodo consequat.
            </AccordionPanel>
          </AccordionItem>
        </Accordion>
      </VStack>
    </VStack>
  )
}

export default Manager