import { Button } from "@chakra-ui/button"
import { Input } from "@chakra-ui/input"
import { HStack, Heading, VStack } from "@chakra-ui/layout"
import { Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/menu"
import { ChevronDownIcon } from "@chakra-ui/icons"
import LeverageSlider from "./Slider/LeverageSlider"
import { useState } from "react"
import { Box } from "@chakra-ui/react"

const Manager = () => {

  const [leverage, setLeverage] = useState(1)
  const [inputValue, setInputValue] = useState<string>("")
  
  const maxLeverage = 10
  // output value is inputValue * leverage, rounded to 4 decimal places if there are decimals
  const outputValue = inputValue ? (Math.round((Number(inputValue) * leverage) * 10000) / 10000).toString() : "0"

  return (
    <VStack gap="1em" w="100%" alignItems="flex-start">
      <Heading as='h2' size='lg' fontWeight={300}>
        Create Position
      </Heading>
      <VStack
        padding="1em"
        border="2px solid black"
        borderRadius="0.5em"
        w="100%"
      >
        <HStack
          w="100%"
          p="1em"
          border="1px solid black"
          borderRadius="0.5em"
          justifyContent="space-between"
        >
          <Input
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            border="none"
            _focusVisible={{
              outline: "none"
            }}
            w="50%"
            type="number"
            p="0"
            h="fit-content"
            fontSize="1.2em"
          />
          <Menu>
            <MenuButton as={Button} rightIcon={<ChevronDownIcon />} w="33%">
              Assets
            </MenuButton>
            <MenuList zIndex={999}>
              <MenuItem>Download</MenuItem>
              <MenuItem>Create a Copy</MenuItem>
              <MenuItem>Mark as Draft</MenuItem>
              <MenuItem>Delete</MenuItem>
              <MenuItem>Attend a Workshop</MenuItem>
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
          border="1px solid black"
          borderRadius="0.5em"
          justifyContent="space-between"
        >
          <Box
            w="50%"
            h="fit-content"
            fontSize="1.2em"
          >
            {outputValue}
          </Box>
          <div>
            USD-3Pool
          </div>
        </HStack>
      </VStack>
    </VStack>
  )
}

export default Manager