import { Button } from "@chakra-ui/button"
import { Input } from "@chakra-ui/input"
import { HStack, Heading, VStack } from "@chakra-ui/layout"
import { Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/menu"
import { ChevronDownIcon } from "@chakra-ui/icons"

const Manager = () => {

  return (
    <VStack gap="1em" w="100%" alignItems="flex-start">
      <Heading as='h2' size='md'>
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
          p="0.5em"
          border="1px solid black"
          borderRadius="0.5em"
          justifyContent="space-between"
        >
          <Input
            border="none"
            _focusVisible={{
              outline: "none"
            }}
            w="50%"
            type="number"
          />
          <Menu>
            <MenuButton as={Button} rightIcon={<ChevronDownIcon />} w="33%">
              Actions
            </MenuButton>
            <MenuList>
              <MenuItem>Download</MenuItem>
              <MenuItem>Create a Copy</MenuItem>
              <MenuItem>Mark as Draft</MenuItem>
              <MenuItem>Delete</MenuItem>
              <MenuItem>Attend a Workshop</MenuItem>
            </MenuList>
          </Menu>
        </HStack>
      </VStack>
    </VStack>
  )
}

export default Manager