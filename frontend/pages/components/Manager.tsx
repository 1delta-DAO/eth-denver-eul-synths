import { Button } from "@chakra-ui/button"
import { Input } from "@chakra-ui/input"
import { HStack, Heading, VStack } from "@chakra-ui/layout"
import { Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/menu"
import { ChevronDownIcon } from "@chakra-ui/icons"
import LeverageSlider from "./Slider/LeverageSlider"
import { useState } from "react"
import { Accordion, AccordionButton, AccordionIcon, AccordionItem, AccordionPanel, Avatar, Box } from "@chakra-ui/react"
import { Pool, PoolAsset, payAssets } from "../src/constants"
import { PoolDetailsVStack } from "./Pools"

interface ManagerProps {
  selectedPool: Pool
}

const Manager: React.FC<ManagerProps> = ({
  selectedPool
}: ManagerProps) => {

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
        padding="1em"
        background="#e7e7e7"
        borderRadius="0.5em"
        w="100%"
        gap="1em"
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
            cursor="pointer"
          />
          <Menu>
            <MenuButton
              as={Button}
              rightIcon={<ChevronDownIcon />}
              minW="35%"
              border="1px solid #e7e7e7"
              background="transparent"
              _hover={{
                background: "#e7e7e7",
              }}
              _active={{
                outline: "none",
                background: "#e7e7e7",
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
          <HStack>
            {
              selectedPool.assets.map((asset, index) => (
                <Avatar
                  key={index}
                  src={asset.icon}
                  name={asset.name}
                  size="xs"
                />
              ))
            }
          </HStack>
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
            <PoolDetailsVStack
              pool={selectedPool}
              style={{
                fontSize: "0.8em",
                gap: "0.3em"
              }}
            />
            </AccordionPanel>
          </AccordionItem>
        </Accordion>
        <Button
          w="100%"
          background="black"
          color="white"
          _hover={{
            background: "#2b2b2b",
          }}
          _active={{
            background: "black",
          }}
          _focus={{
            outline: "none",
          }}
        >
          Create Position
        </Button>
      </VStack>
    </VStack>
  )
}

export default Manager