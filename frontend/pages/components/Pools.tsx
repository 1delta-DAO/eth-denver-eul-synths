import { Grid, Heading } from "@chakra-ui/layout"
import { Pool, pools } from "../src/constants"
import { Avatar, Box, HStack, VStack, Text } from "@chakra-ui/react"

const PoolCard = (pool: Pool) => {
  return (
    <Box
      p="0.5em"
      borderRadius="0.5em"
      bg="#dddddd"
    >
      <VStack
        w="100%"
        p="1em"
        bg="white"
        borderRadius="0.5em"
      >
        <HStack
          w="100%"
          justifyContent="space-between"
          fontSize="1.3em"
        >
          <Text>
            {pool.assets.map((asset) => asset.symbol).join("-")}
          </Text>
          <HStack>
            {
              pool.assets.map((asset, index) => (
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
    </Box>
  )
}

const Pools = () => {
  
  return (
    <VStack
      width="100%"
      gap="1em"
      alignItems="flex-start"
    >
      <Heading as='h2' size='lg' fontWeight={300}>
        Pools
      </Heading>
      <Grid
        templateColumns="repeat(2, 1fr)"
        gap="1em"
        w="100%"
      >
        {pools.map((pool, index) => (
          <PoolCard key={index} {...pool} />
        ))}
      </Grid>
    </VStack>
  )
}

export default Pools