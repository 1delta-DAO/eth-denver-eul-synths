import { Grid, Heading } from "@chakra-ui/layout"
import { Pool, dexs, pools } from "../constants"
import { Avatar, Box, HStack, VStack, Text } from "@chakra-ui/react"
import { formatNumber, formatRatioToPercent } from "../formatters"
import useDevice from "../hooks/useDevice"

interface PoolDetailsVStackProps {
  pool: Pool,
  style?: React.CSSProperties
}

export const PoolDetailsVStack = ({
  pool,
  style
}: PoolDetailsVStackProps) => {

  const {isTabletMedium, isMobile} = useDevice()

  return (
    <VStack w="100%" style={style} fontSize={isTabletMedium ? "0.8em" : "0.9em"} gap={isMobile ? "0.25em" : ""}>
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
      {
        pool.dex &&
        <HStack justifyContent="space-between" w="100%" fontSize="1.2em">
          <Text>DEX</Text>
          <Avatar
            src={dexs.find((dex) => dex.name === pool.dex)?.icon}
            name={pool.dex}
            size="xs"
          />
        </HStack>
      }
    </VStack>
  )
}

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

  const {isTabletMedium, isMobile} = useDevice()

  return (
    <Box
      p={isMobile ? "0.75em" : "1em"}
      borderRadius="0.5em"
      bg={isSelected ? "#2b2b2b" : "#e7e7e7"}
      cursor={isSelected ? "default" : "pointer"}
      _hover={{
        background: "#2b2b2b",
        transform: isSelected ? "" : "scale(0.97)"
      }}
      transition="all 0.1s ease-in-out"
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
          fontSize={isMobile ? "1.35em" : "1.5em"}
          lineHeight={isMobile ? 1 : "normal"}
        >
          <Text fontSize={isTabletMedium ? "0.9em" : ""}>
            {pool.assets.map((asset) => asset.symbol).join("-")}
          </Text>
          <HStack gap="0" marginRight={pool.assets.length * -0.15 + "em"}>
            {
              pool.assets.map((asset, index) => (
                <Avatar
                  key={index}
                  src={asset.icon}
                  name={asset.name}
                  size="xs"
                  position="relative"
                  left={index * -0.5 + "em"}
                />
              ))
            }
          </HStack>
        </HStack>
        <PoolDetailsVStack
          pool={pool}
        />
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

  const {isMobile} = useDevice()
  
  return (
    <VStack
      width="100%"
      gap="1em"
      alignItems="flex-start"
    >
      <Heading as='h2' size={isMobile ? 'md' : 'lg'} fontWeight={300}>
        Select Pool
      </Heading>
      <Grid
        templateColumns={isMobile ? "repeat(1, 1fr)" : "repeat(2, 1fr)"}
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