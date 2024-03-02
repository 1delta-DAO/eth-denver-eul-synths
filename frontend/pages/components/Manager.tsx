import { Button } from "@chakra-ui/button"
import { Input } from "@chakra-ui/input"
import { HStack, Heading, VStack } from "@chakra-ui/layout"
import { Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/menu"
import { ChevronDownIcon } from "@chakra-ui/icons"
import LeverageSlider from "./Slider/LeverageSlider"
import { useEffect, useState } from "react"
import { Accordion, AccordionButton, AccordionIcon, AccordionItem, AccordionPanel, Avatar, Box, Spinner, Text } from "@chakra-ui/react"
import { Pool, PoolAsset } from "../src/constants"
import { PoolDetailsVStack } from "./Pools"
import { useAccount, useBalance } from "wagmi"
import { formatNumber, parseBigInt } from "../src/formatters"
import { useApprove } from "../hooks/useApprove"
import { sepolia } from "viem/chains"
import { useCallBatch } from "../hooks/useCallBatch"

interface ManagerProps {
  selectedPool: Pool
  prices: Record<string, number> | null
}

const Manager: React.FC<ManagerProps> = ({
  selectedPool,
  prices
}: ManagerProps) => {

  const defaultLeverage = 2
  const [leverage, setLeverage] = useState(defaultLeverage)
  const [inputValue, setInputValue] = useState<string>("")

  const maxLeverage = 10
  const outputValue = 
    inputValue ? Math.round((Number(inputValue) * leverage * 0.9988) * 100000) / 100000 : 0

  const [payAsset, setPayAsset] = useState<PoolAsset>(selectedPool.assets[0])

  useEffect(() => {
    setPayAsset(selectedPool.assets[0])
    setInputValue("")
    setLeverage(defaultLeverage)
  }, [selectedPool])

  useEffect(() => {
    setInputValue("")
    setLeverage(defaultLeverage)
  }, [payAsset])

  const account = useAccount()

  const userNotConnected = !account.address
  const noInputValue = inputValue === "" || inputValue === "0"

  const payAssetPrice = prices ? prices[payAsset.symbol] : 0
  const dollarValue = inputValue ? Number(inputValue) * payAssetPrice : 0

  const {
    allowance,
    approve,
  } = useApprove({ assetSymbol: payAsset.symbol })

  const batch = useCallBatch()

  const approved = allowance >= Number(inputValue)

  const [txLoading, setTxLoading] = useState(false)

  const executeTx = async () => {
    if (!approved && account.address) {
      setTxLoading(true)
      await approve(Number(inputValue))
      setTxLoading(false)
    } else {
      if (approved && account.address) {
        const depo = Number(inputValue ?? '0')
        setTxLoading(true)
        await batch(depo, (leverage - 1) * depo)
        setTxLoading(false)
      }
    }
  }

  const balanceResult = useBalance({
    token: payAsset.address as `0x${string}`,
    address: account.address as `0x${string}`,
    chainId: sepolia.id,
  })

  const balance =
    balanceResult.data?.symbol === payAsset.symbol ||
      balanceResult.data?.symbol === "DAI Stablecoin" ?
      parseBigInt(balanceResult.data.value, payAsset.decimals) :
      0

  const insufficientBalance = balance === 0 || Number(inputValue) > balance

  return (
    <VStack gap="1em" w="100%" alignItems="flex-start">
      <Heading as='h2' size='lg' fontWeight={300}>
        Create Leveraged Position
      </Heading>
      <VStack
        padding="1em"
        background="#e7e7e7"
        borderRadius="0.5em"
        w="100%"
        gap="1em"
      >
        <VStack
          w="100%"
          p="1em"
          borderRadius="0.5em"
          background="white"
          gap="0.5em"
        >
          <HStack
            w="100%"
            justifyContent="space-between"
            height="1em"
          >
            <Text lineHeight={1} fontSize="0.8em">
              Pay with
            </Text>
            {
              balance &&
              <HStack>
                <Text lineHeight={1} fontSize="0.8em">
                  {`Balance: ${formatNumber(balance)}`}
                </Text>
                <Button
                  size="xs"
                  height="auto"
                  bg="transparent"
                  padding="0"
                  _hover={{
                    background: "transparent",
                  }}
                  onClick={() => setInputValue(balance.toString())}
                >
                  Max
                </Button>
              </HStack>
            }
          </HStack>
          <HStack
            w="100%"
            justifyContent="space-between"
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
                height="auto"
                padding="0.5em"
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
                  selectedPool.assets.map((asset) => (
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
          <HStack
            w="100%"
            justifyContent="space-between"
          >
            <Text lineHeight={1} fontSize="0.8em">
              {inputValue && `$${formatNumber(dollarValue)}`}
            </Text>
            <Text lineHeight={1} fontSize="0.8em">
              {payAsset.name}
            </Text>
          </HStack>
        </VStack>
        <LeverageSlider
          value={leverage}
          maxLeverage={maxLeverage}
          tooltipSymbol={"x"}
          onChange={setLeverage}
        />
        <VStack
          w="100%"
          p="1em"
          borderRadius="0.5em"
          background="white"
          gap="0.25em"
        >
          <HStack
            w="100%"
          >
            <Text lineHeight={1} fontSize="0.8em">
              Deposit Pool Token to
            </Text>
            <Avatar
              src="https://storage.googleapis.com/subgraph-images/1656114240805euler-transparent.png"
              name="Euler"
              size="2xs"
            />
            <Text lineHeight={1} fontSize="0.8em">
              Euler
            </Text>
          </HStack>
          <HStack
            w="100%"
            justifyContent="space-between"
          >
            <Box
              w="50%"
              h="fit-content"
              fontSize="1.5em"
            >
              {formatNumber(outputValue)}
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
        </VStack>
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
          background="#2b2b2b"
          color="white"
          isDisabled={
            userNotConnected ||
            noInputValue ||
            txLoading ||
            insufficientBalance
          }
          _hover={{
            background: "black",
          }}
          _active={{
            background: "black",
          }}
          _focus={{
            outline: "none",
          }}
          _disabled={{
            background: "#818181",
            cursor: "not-allowed",
          }}
          onClick={executeTx}
          gap="0.5em"
        >
          {
            userNotConnected ? "Connect Wallet" :
              noInputValue ? "Insert Amount" :
                insufficientBalance ? "Insufficient Balance" :
                  !approved && !txLoading ? "Approve Asset" :
                    !approved && txLoading ? "Approving" :
                      "Create Position"
          }
          {
            txLoading && <Spinner size="xs" />
          }
        </Button>
      </VStack>
    </VStack>
  )
}

export default Manager