import { Grid, Heading } from "@chakra-ui/layout"
import { Pool, pools } from "../src/constants"
import { Avatar, Box, HStack, VStack, Text } from "@chakra-ui/react"
import { formatNumber, formatRatioToPercent } from "../src/formatters"

interface PoolCardProps {
  isSelected: boolean,
  setPool: (pool: Pool) => void,
  pool: Pool
}

const PoolCard: React.FC<PoolCardProps> = ({
  isSelected,
  setPool,
  pool
}: PoolCardProps) => {

  return (
    <Box
      p="0.5em"
      borderRadius="0.5em"
      bg={isSelected ? "#eeeeee" : "#dddddd"}
      cursor={isSelected ? "default" : "pointer"}
      _hover={{
        background: "#eeeeee",
        transform: isSelected ? "" : "scale(0.97)"
      }}
      transition="all 0.2s ease-in-out"
      onClick={() => !isSelected && setPool(pool)}
      _active={{
        transform: isSelected ? "" : "scale(0.95)"
      }}
    >
      <VStack
        w="100%"
        p="1em"
        bg="white"
        borderRadius="0.3em"
        h="100%"
        gap="1em"
      >
        <HStack
          w="100%"
          justifyContent="space-between"
          fontSize="1.5em"
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
        <VStack w="100%">
          <HStack justifyContent="space-between" w="100%" fontSize="1.2em">
            <Text>APR</Text>
            <Text>{formatRatioToPercent(pool.apr)}</Text>
          </HStack>
          {
            pool.stakingApr && (
              <HStack justifyContent="space-between" w="100%" fontSize="1.2em">
                <Text>Staking APR</Text>
                <Text>{formatRatioToPercent(pool.stakingApr)}</Text>
              </HStack>
            )
          }
          <HStack justifyContent="space-between" w="100%" fontSize="1.2em">
            <Text>TVL</Text>
            <Text>${formatNumber(pool.tvl)}</Text>
          </HStack>
          {
            pool.totalSupply && (
              <HStack justifyContent="space-between" w="100%" fontSize="1.2em">
                <Text>Total Supply</Text>
                <Text>{formatNumber(pool.totalSupply)}</Text>
              </HStack>
            )
          }
        </VStack>
      </VStack>
    </Box>
  )
}

interface PoolsProps {
  selectedPool: Pool,
  setPool: (pool: Pool) => void
}

const Pools: React.FC<PoolsProps> = ({
  selectedPool,
  setPool
}: PoolsProps) => {
  
  return (
    <VStack
      width="100%"
      gap="1em"
      alignItems="flex-start"
    >
      <Heading as='h2' size='lg' fontWeight={300}>
        Select Pool
      </Heading>
      <Grid
        templateColumns="repeat(2, 1fr)"
        gap="1em"
        w="100%"
      >
        {pools.map((pool, index) => (
          <PoolCard
            isSelected={pool.assets === selectedPool.assets}
            setPool={setPool}
            key={index}
            pool={pool}
          />
        ))}
      </Grid>
    </VStack>
  )
}

export default Pools